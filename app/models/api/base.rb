# frozen_string_literal: true
# Base class for API v0.5, now used for Warehouse message rendering, the actual
# api is no longer exposed.
# @note Originally the warehouse was built nightly by calls the the v0.5 API.
#       When the warehouse was switched to a queue based system the same JSON
#       exposed via the API was used to form the message payload.
class Api::Base # rubocop:todo Metrics/ClassLength
  class_attribute :includes
  self.includes = []

  # TODO[xxx]: This class is in a state of flux at the moment, please don't hack at this too much!
  #
  # Basically this is in a transition as I move more of the behaviour of the API into these model classes,
  # and out of the controllers, and will eventually be much clearer.  And, although this class looks
  # extremely complex, it's purpose is to make subclasses much, much easier to write and maintain.

  #--
  # The following block defines the methods used by the Api::BaseController class.
  #++
  class << self
    def create!(params)
      model_class.create!(attributes_from_json(params))
    end

    def update!(object, params)
      object.update!(attributes_from_json(params))
    end

    # Maps the attribute names in the errors to their JSON counterparts, so that the end user gets
    # the correct information.
    def map_attribute_to_json_attribute_in_errors(attribute_errors)
      attribute_errors.transform_keys { |a| json_attribute_for_attribute(*a.to_s.split('.')) }
    end
  end

  #--
  # This block defines the methods used to convert objects to JSON.  You'll find the code that calls this
  # in lib/api_tools.rb, as well as in the Api::AssetsController.
  #++
  class << self
    # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
    def to_hash(object) # rubocop:todo Metrics/CyclomaticComplexity
      # If the object is nil we get a chance to use the 'default' object that was specified.  By
      # default the "default" object is nil, but you can override it for associations through the
      # with_association(:name, :if_nil_use => :some_method).
      object ||= default_object
      return {} if object.nil?

      json_attributes = {}
      json_attributes['deleted_at'] = Time.zone.now if object.destroyed?

      attribute_to_json_attribute_mappings.each do |attribute, json_attribute|
        json_attributes[json_attribute] = object.send(attribute)
      end
      associations.each do |_association, helper|
        value = helper.target(object)
        json_attributes.update(helper.to_hash(value))
        helper.newer_than(value, json_attributes['updated_at']) do |timestamp|
          json_attributes['updated_at'] = timestamp
        end
      end
      nested_has_many_associations.each do |_association, helper|
        values = helper.target(object)
        all_targets =
          values.map do |value|
            helper.newer_than(value, json_attributes['updated_at']) do |timestamp|
              json_attributes['updated_at'] = timestamp
            end
            helper.to_hash(value)
          end
        json_attributes.update(helper.alias.to_s => all_targets)
      end
      extra_json_attribute_handlers.each { |handler| handler.call(object, json_attributes) }
      json_attributes
    end

    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

    def to_hash_for_list(object)
      raise StandardError, 'The object is nil, which is highly unexpected!' if object.nil?

      json_attributes = {}
      attribute_to_json_attribute_mappings_for_list.each do |attribute, json_attribute|
        json_attributes[json_attribute] = object.send(attribute)
      end
      json_attributes
    end
  end

  #--
  # This code is called when constructing a runtime class for the I/O of a class that does not have
  # a specific I/O class.
  #++
  class << self
    # The default behaviour for any model I/O is to write out all of the columns as they appear.  Some of
    # the columns are ignored, a few manipulated, but mostly it's a direct copy.
    # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
    def render_class_for_model(model) # rubocop:todo Metrics/CyclomaticComplexity
      render_class = Class.new(self)

      # NOTE: It's quite annoying that you don't have any access to the inheritable class attributes from
      # within the Class.new block above, so we have to do a separate instance_eval to get it to work.
      render_class.instance_eval do
        self.model_class = model
        model.column_names.each { |column| map_attribute_to_json_attribute(column, column) }

        # TODO[xxx]: It's better that some of these are decided at generation, rather than execution, time.
        extra_json_attributes do |object, json_attributes|
          json_attributes['uuid'] = object.uuid if object.respond_to?(:uuid)

          # Users and roles
          json_attributes['user'] = object.user.nil? ? 'unknown' : object.user.login if object.respond_to?(:user)
          if object.respond_to?(:roles)
            object.roles.each do |role|
              json_attributes[role.name.underscore] = role.users.map do |user|
                { login: user.login, email: user.email, name: user.name }
              end
            end
          end
        end
      end
      render_class
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end

  # The model class that our I/O methods are responsible for
  class_attribute :model_class

  def self.renders_model(model)
    self.model_class = model
  end

  # Contains the mapping from the ActiveRecord attribute to the key in the JSON hash
  class_attribute :attribute_to_json_attribute_mappings, instance_writer: false
  self.attribute_to_json_attribute_mappings = {}

  # TODO[xxx]: Need to warn about 'id' not being 'internal_id'
  def self.map_attribute_to_json_attribute(attribute, json_attribute = attribute)
    self.attribute_to_json_attribute_mappings =
      attribute_to_json_attribute_mappings.merge(attribute.to_sym => json_attribute.to_s)
  end

  # Contains the mapping from the ActiveRecord association to the I/O object that can output it.
  class_attribute :associations, instance_writer: false
  self.associations = {}

  # Contains the mapping from the ActiveRecord association to the I/O object that can output it.
  class_attribute :nested_has_many_associations
  self.nested_has_many_associations = {}

  # rubocop:todo Metrics/PerceivedComplexity, Metrics/AbcSize
  def self.newer_than(object, timestamp) # rubocop:todo Metrics/CyclomaticComplexity
    return if object.nil? || timestamp.nil?

    _modified, object_timestamp = false, (object.respond_to?(:updated_at) ? object.updated_at : timestamp) || timestamp
    timestamp, modified = object_timestamp, true if object_timestamp > timestamp
    associations.each_value do |helper|
      helper.newer_than(helper.target(object), timestamp) { |t| timestamp, modified = t, true }
    end
    nested_has_many_associations.each_value do |helper|
      helper.target(object).each { |child| helper.newer_than(child, timestamp) { |t| timestamp, modified = t, true } }
    end
    yield(timestamp) if modified
  end

  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

  # Returns the default object to use (by default this is 'nil') and can be overridden by passing
  # ':if_nil_use => :some_function_that_returns_default_object' to with_association.
  def self.default_object
    nil
  end

  # rubocop:todo Metrics/MethodLength
  def self.with_association(association, options = {}, &) # rubocop:todo Metrics/AbcSize
    association_helper = Class.new(Api::Base)
    association_helper.class_eval(&)
    association_helper.singleton_class.class_eval do
      alias_method(:default_object, options[:if_nil_use]) if options.key?(:if_nil_use)
      define_method(:lookup_by) { options[:lookup_by] }
      define_method(:association) { association }
      define_method(:target) do |parent|
        target_object = parent.send(association)
        options[:decorator] && target_object ? options[:decorator].new(target_object) : target_object
      end
    end
    self.associations = ({}) if associations.empty?
    associations[association.to_sym] = association_helper
  end

  # rubocop:enable Metrics/MethodLength

  # rubocop:todo Metrics/MethodLength
  def self.with_nested_has_many_association(association, options = {}, &) # rubocop:todo Metrics/AbcSize
    association_helper = Class.new(Api::Base)
    association_helper.class_eval(&)
    association_helper.singleton_class.class_eval do
      define_method(:association) { association }
      define_method(:alias) { options[:as] || association }
      define_method(:target) do |parent|
        target_object = parent.send(association)
        options[:decorator] && target_object ? options[:decorator].new(target_object) : target_object
      end
    end
    self.nested_has_many_associations = ({}) if nested_has_many_associations.empty?
    nested_has_many_associations[association.to_sym] = association_helper
  end

  # rubocop:enable Metrics/MethodLength

  def self.performs_lookup?
    !!lookup_by
  end

  def self.lookup_associated_record_from(json_attributes)
    attributes = convert_json_attributes_to_attributes(json_attributes)
    return unless attributes.key?(lookup_by)

    search_parameters = { lookup_by => attributes[lookup_by] }
    yield(association.to_s.classify.constantize.find_by(search_parameters))
  end

  # Contains the mapping from the ActiveRecord attribute to the key in the JSON hash when listing objects
  class_attribute :attribute_to_json_attribute_mappings_for_list

  self.attribute_to_json_attribute_mappings_for_list = {
    id: 'id',
    uuid: 'uuid', # TODO[xxx]: if respond_to?(:uuid)
    url: 'url', # TODO[xxx]: if respond_to?(:uuid)
    name: 'name' # TODO[xxx]: if respond_to?(:name)
  }

  # Additional JSON attribute handling, that cannot be done with the simple stuff, should be passed
  # done through a block
  class_attribute :extra_json_attribute_handlers, instance_writer: false
  self.extra_json_attribute_handlers = []

  def self.extra_json_attributes(&block)
    self.extra_json_attribute_handlers = [] if extra_json_attribute_handlers.empty?
    extra_json_attribute_handlers.push(block)
  end

  class << self
    def attributes_from_json(params)
      convert_json_attributes_to_attributes(params[model_class.name.underscore])
    end

    # rubocop:todo Metrics/MethodLength
    def convert_json_attributes_to_attributes(json_attributes) # rubocop:todo Metrics/AbcSize
      return {} if json_attributes.blank?

      attributes = {}
      attribute_to_json_attribute_mappings.each do |attribute, json_attribute|
        attributes[attribute] = json_attributes[json_attribute] if json_attributes.key?(json_attribute)
      end
      associations.each do |association, helper|
        if helper.performs_lookup?
          helper.lookup_associated_record_from(json_attributes) do |associated_record|
            attributes[:"#{association}_id"] = associated_record.try(:id)
          end
        else
          association_attributes = helper.convert_json_attributes_to_attributes(json_attributes)
          attributes[:"#{association}_attributes"] = association_attributes unless association_attributes.empty?
        end
      end
      attributes
    end

    # rubocop:enable Metrics/MethodLength

    # rubocop:todo Metrics/MethodLength
    def json_attribute_for_attribute(attribute_or_association, *rest) # rubocop:todo Metrics/AbcSize
      json_attribute = attribute_to_json_attribute_mappings[attribute_or_association.to_sym]
      if json_attribute.blank?
        # If we have reached the end of the line, and the attribute_or_association is for what looks like
        # an association, then we'll look it up without the '_id' and return that value.
        if attribute_or_association.to_s =~ /_id$/ && rest.empty?
          association = associations[attribute_or_association.to_s.sub(/_id$/, '').to_sym]
          raise StandardError, "Unexpected association #{attribute_or_association.inspect}" if association.nil?

          return association.json_attribute_for_attribute(:name)
        end
        json_attribute = associations[attribute_or_association.to_sym].json_attribute_for_attribute(*rest)
      end
      if json_attribute.blank?
        raise StandardError, "Unexpected attribute #{attribute_or_association.inspect} does not appear to be mapped"
      end

      json_attribute
    end
    # rubocop:enable Metrics/MethodLength
  end
end
