# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Core::Io::Base::JsonFormattingBehaviour
  def self.extended(base)
    base.class_eval do
      extend ::Core::Io::Base::JsonFormattingBehaviour::Input
      extend ::Core::Io::Base::JsonFormattingBehaviour::Output

      class_attribute :attribute_to_json_field, instance_writer: false
      self.attribute_to_json_field = {}
      delegate :json_field_for, to: 'self.class'
    end
  end

  # NOTE: This one is OK!
  def as_json(options = nil)
    options ||= {}
    object    = options.delete(:object)
    object_json(object, options)
  end

  #--
  # Very root level does absolutely nothing useful!
  #++
  def object_json(*args)
  end

  def json_field_for(attribute)
    return attribute_to_json_field[attribute.to_s] if attribute_to_json_field.key?(attribute.to_s)

    # We have to assume that this could be an association that is being exposed, in which case we'll
    # need to determine the I/O class that deals with it and hand off the error handling to it.
    association, *association_parts = attribute.to_s.split('.')
    return attribute.to_s if association_parts.empty?
    reflection = model_for_input.reflections[association]
    return attribute.to_s if reflection.nil?

    # TODO: 'association' here should really be garnered from the appropriate endpoint
    association_json_field = ::Core::Io::Registry.instance.lookup_for_class(reflection.klass).json_field_for(association_parts.join('.'))
    "#{association}.#{association_json_field}"
  end

  def set_json_root(name)
    @json_root = name.to_sym
  end

  def json_root
    @json_root or raise StandardError, "JSON root is not set for #{name}"
  end

  def api_root
    json_root.to_s.pluralize
  end

  def define_attribute_and_json_mapping(mapping)
    parse_mapping_rules(mapping) do |attribute_to_json, json_to_attribute|
      attribute_to_json_field.merge!(Hash[attribute_to_json])
      generate_object_to_json_mapping(attribute_to_json)
      generate_json_to_object_mapping(json_to_attribute)
    end
  end

  VALID_LINE_REGEXP = /^\s*((?:[a-z_][\w_]*\.)*[a-z_][\w_]*[?!]?)\s*(<=|<=>|=>)\s*((?:[a-z_][\w_]*\.)*[a-z_][\w_]*)\s*$/

  def parse_mapping_rules(mapping)
    attribute_to_json, json_to_attribute = [], []
    StringIO.new(mapping).each_line do |line|
      next if line.blank? or line =~ /^\s*#/
      match = VALID_LINE_REGEXP.match(line) or raise StandardError, "Invalid line: #{line.inspect}"
      attribute_to_json.push([match[1], match[3]]) if (match[2] =~ /<?=>/)
      json_to_attribute.push([match[3], (match[2] =~ /<=>?/) ? match[1] : nil])
    end
    yield(attribute_to_json, json_to_attribute)
  end
  private :parse_mapping_rules
end
