#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
module ::Core::Io::Base::JsonFormattingBehaviour::Input
  class ReadOnlyAttribute < ::Core::Service::Error
    def initialize(attribute)
      super('is read-only')
      @attribute = attribute
    end

    def api_error(response)
      response.content_error(422, { @attribute => [ self.message ] })
    end
  end

  def self.extended(base)
    base.class_eval do
      class_attribute :model_for_input, :instance_writer => false
      extend AssociationHandling
    end
  end

  def set_model_for_input(model)
    self.model_for_input =  model
  end

  def generate_json_to_object_mapping(json_to_attribute)
    code = []

    # Split the mappings into two to make things easier.  Read only attributes are easily
    # handled right now, provided there is not a read_write one that shares their name.
    read_only, read_write = json_to_attribute.partition { |_, v| v.nil? }
    common_keys = read_only.map(&:first) & read_write.map(&:first)
    read_only.delete_if { |k,_| common_keys.include?(k) }
    code.concat(read_only.map do |json, _|
      %Q{process_if_present(params, #{json.split('.').inspect}) { |_| raise ReadOnlyAttribute, #{json.inspect} }}
    end)

    # Now the harder bit: for attribute we need to work out how we would fill in the attribute
    # structure for an update_attributes! call.
    initial_structure = {}
    read_write.each do |json, attribute|
      steps       = attribute.split('.').map(&:to_sym)
      trunk, leaf = steps[0..-2], steps.last

      # This bit ends up with the 'path' for the inner bit of the attribute (i.e. if the attribute
      # was 'a.b.c.d' then the inner bit is 'a.b.c' and this path could be 'a_attributes,
      # b_attributes, c_attributes') and the final model, or rather association, that we end at.
      # 'model' is nil if there is no association and we're assuming that we need a Hash of
      # some form.
      model, path = trunk.inject([ model_for_input, [] ]) do |(model, parts), step|
        next_model, next_step =
          if model.nil?
            [ nil, step ]
          elsif association = model.reflections[step]
            raise StandardError, "Nested attributes only works with belongs_to or has_one" unless [ :belongs_to, :has_one ].include?(association.macro.to_sym)
            [ association.klass, :"#{step}_attributes" ]
          else
            [ nil, step ]
          end

        [ next_model, parts << next_step ]
      end

      # Build the necessary structure for the attributes.  The code can also be generated
      # based on the information we have generated.  If we ended at an association and the
      # leaf is also an association then we have to change the behaviour based on the incoming
      # JSON.
      path.inject(initial_structure) { |part, step| part[step] ||= {} }
      code << "process_if_present(params, #{json.split('.').inspect}) do |value|"
      if path.empty?
        code << "  attributes.tap do |section|"
      else
        code << "  #{path.inspect}.inject(attributes) { |a,s| a[s] }.tap do |section|"
      end

      if model.nil?
        code << "    section[#{leaf.inspect}] = value #nil"
      elsif model.respond_to?(:reflections) and association = model.reflections[leaf]
        code << "    handle_#{association.macro}(section, #{leaf.inspect}, value, object)"
      elsif model.respond_to?(:klass) and association = model.klass.reflections[leaf]
        code << "    handle_#{association.macro}(section, #{leaf.inspect}, value, object)"
      else
        code << "    section[#{leaf.inspect}] = value"
      end
      code << "  end"
      code << "end"
    end

    low_level(('-' * 30) << self.name << ('-' * 30))
    code.map(&method(:low_level))
    low_level(('=' * 30) << self.name << ('=' * 30))

    # Generate the code that the instance will actually use ...
    line = __LINE__ + 1
    class_eval(%Q{
      def self.map_parameters_to_attributes(params, object = nil, nested_in_another_model = false)
        #{initial_structure.inspect}.tap do |attributes|
          attributes.deep_merge!(super)
          params = params.fetch(json_root.to_s, {}) unless nested_in_another_model
          #{code.join("\n")}
        end
      end
    }, __FILE__, line)
  end
  private :generate_json_to_object_mapping

  # If the specified path is present all of the way to the end then the value at the
  # leaf is yielded, otherwise this method simply returns.
  def process_if_present(json, path)
    value = path.inject(json) do |current,step|
      return unless current.respond_to?(:key?)    # Could be nested attribute but not present!
      return unless current.key?(step)
      current[step]
    end
    yield(value)
  end
  private :process_if_present

  module AssociationHandling
    def association_class(association, object)
      object.try(association).try(:class) || model_for_input.reflections[association.to_sym].klass
    end
    private :association_class

    def handle_belongs_to(attributes, attribute, json, object)
      if json.is_a?(Hash)
        uuid       = json.delete('uuid')
        associated = association_class(attribute, object)
        if uuid.present?
          attributes[attribute] = load_uuid_resource(uuid)
        elsif associated.present?
          io = ::Core::Io::Registry.instance.lookup_for_class(associated)
          attributes[:"#{attribute}_attributes"] = io.map_parameters_to_attributes(json, nil, true)
        else
          # We really don't have any idea here so we're just going to take what's there as it!
          attributes[:"#{attribute}_attributes"] = json
        end
      else
        attributes[attribute] = load_uuid_resource(json)
      end
    end
    private :handle_belongs_to

    def load_uuid_resource(uuid)
      record = Uuid.include_resource.lookup_single_uuid(uuid).resource
      ::Core::Io::Registry.instance.lookup_for_object(record).eager_loading_for(record.class).include_uuid.find(record.id)
    end
    private :load_uuid_resource

    def handle_has_many(attributes, attribute, json, object)
      if json.first.is_a?(Hash)
        uuids             = Uuid.include_resource.lookup_many_uuids(json.map { |j| j['uuid'] })
        uuid_to_resource  = Hash[uuids.map { |uuid| [uuid.external_id, uuid.resource] }]
        mapped_attributes = json.map do |j|
          uuid     = j.delete('uuid') or raise StandardError, 'UUID missing from has_many update'
          delete   = j.delete('delete')
          resource = uuid_to_resource[uuid]
          io       = ::Core::Io::Registry.instance.lookup_for_object(resource)
          io.map_parameters_to_attributes(j, resource, true).tap do |mapped|
            mapped[:id]     = resource.id                 # UUID becomes ID
            mapped[:delete] = delete unless delete.nil?   # Are we deleting this one?
          end
        end

        attributes[:"#{attribute}_attributes"] = mapped_attributes
      else
        attributes[attribute] = Uuid.include_resource.lookup_many_uuids(json).map(&:resource)
      end
    end
    private :handle_has_many
  end
end
