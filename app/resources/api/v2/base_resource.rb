# frozen_string_literal: true

module Api
  module V2
    # Provides extensions to JSONAPI::Resource as well as global behaviour
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class BaseResource < JSONAPI::Resource
      abstract

      # Loaded on the base class so that they can be loaded globally.
      Purpose.descendants.each { |subclass| model_hint model: subclass, resource: :purpose }
      Plate.descendants.each { |subclass| model_hint model: subclass, resource: :plate }
      Tube.descendants.each { |subclass| model_hint model: subclass, resource: :tube }
      Request.descendants.each { |subclass| model_hint model: subclass, resource: :request }

      # This extension allows the writeonly property to be used on attributes/relationships
      #  This avoids the need to override fetchable_fields on
      # every resource.
      def fetchable_fields
        super - self.class._attributes.select { |_attr, options| options[:writeonly] }.keys -
          self.class._relationships.select { |_rel_key, rel| rel.options[:writeonly] }.keys
      end

      # This extension allows the immutable property to be used on attributes/relationships
      def self.updatable_fields(context)
        super - _attributes.select { |_attr, options| options[:immutable] }.keys -
          _relationships.select { |_rel_key, rel| rel.options[:immutable] }.keys
      end

      # Eager load specified models by default. Useful when attributes are
      # dependent on an associated model.
      def self.default_includes(*inclusions)
        @default_includes = inclusions.freeze
      end

      def self.inclusions
        @default_includes || [].freeze
      end

      # Extends the default behaviour to add our default inclusions if provided
      def self.records_for_populate(*_args)
        if @default_includes.present?
          super.preload(*inclusions)
        else
          super
        end
      end

      # Monkey patch for issue: https://github.com/cerebris/jsonapi-resources/issues/1160
      # Note: The example patch is against 0.10.5, which we're blocked from due to other issues
      def _replace_polymorphic_to_one_link(relationship_type, key_value, key_type, options)
        key_model_class = self.class.resource_klass_for(key_type.to_s)._model_class
        super(relationship_type, key_value, key_model_class, options)
      end
    end
  end
end
