# frozen_string_literal: true

module Api
  module V2
    # Provides extensions to JSONAPI::Resource as well as global behaviour
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class BaseResource < JSONAPI::Resource
      abstract
      # This extension allows the readonly property to be used on attributes/relationships
      # prior to the 0.10 upgrade. This avoids the need to override updatable_fields on
      # every resource. Readonly does not work on attributes in 0.9 by default
      # This can be removed as soon as we update to 0.10, which is currently only in alpha
      def self.updatable_fields(context)
        super - _attributes.select { |_attr, options| options[:readonly] }.keys -
          _relationships.select { |_rel_key, rel| rel.options[:readonly] }.keys
      end

      # Eager load specified models by default. Useful when attributes are
      # dependent on an associated model.
      def self.default_includes(*inclusions)
        @default_includes = inclusions
      end

      def self.inclusions
        @default_includes
      end

      # Extends the default bheaviour to add our default inclusions if provided
      def self.apply_includes(records, options = {})
        if @default_includes.present?
          super.includes(*inclusions)
        else
          super
        end
      end

      # The majority of this is lifted from JSONAPI::Resource
      # We've had to modify the when Symbol chunk to handle nested includes
      # We disable the cops for the shared section to avoid accidental drift
      # due to auto-correct.
      # rubocop:disable all
      def self.resolve_relationship_names_to_relations(resource_klass, model_includes, options = {})
        case model_includes
          when Array
            return model_includes.map do |value|
              resolve_relationship_names_to_relations(resource_klass, value, options)
            end
          when Hash
            model_includes.keys.each do |key|
              relationship = resource_klass._relationships[key]
              value = model_includes[key]
              model_includes.delete(key)
              model_includes[relationship.relation_name(options)] = resolve_relationship_names_to_relations(relationship.resource_klass, value, options)
            end
            return model_includes
          when Symbol
            relationship = resource_klass._relationships[model_includes]
            # rubocop:enable all
            # MODIFICATION BEGINS
            inclusions = relationship.resource_klass.inclusions || []
            { relationship.relation_name(options) => inclusions }
          # MODIFICATION ENDS
        end
      end
    end
  end
end
