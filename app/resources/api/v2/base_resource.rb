# frozen_string_literal: true

module Api
  module V2
    # @api V2
    # @abstract
    #
    # @todo This documentation does not yet include complete descriptions of methods and what this class offers to its
    #   sub-classes.
    #
    # Provides a base class for JSON:API representations of {ApplicationRecord} sub-classes.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class BaseResource < JSONAPI::Resource
      abstract

      # Loaded on the base class so that they can be loaded globally.
      Order.descendants.each { |subclass| model_hint model: subclass, resource: :order }
      Purpose.descendants.each { |subclass| model_hint model: subclass, resource: :purpose }
      Plate.descendants.each { |subclass| model_hint model: subclass, resource: :plate }
      Tube.descendants.each { |subclass| model_hint model: subclass, resource: :tube }
      Request.descendants.each { |subclass| model_hint model: subclass, resource: :request }
      Transfer.descendants.each { |subclass| model_hint model: subclass, resource: :transfer }

      # These extensions allow the use of readonly, write_once and writeonly properties.
      #   readonly - The attribute/relationship can be read but not written to.
      #   write_once - The attribute/relationship can be written to once on creation but not updated.
      #   writeonly - The attribute/relationship can be written to but not read.
      # This avoids the need to override self.creatable_fields, self.updatable_fields and fetchable_fields on every
      # resource.
      # readonly does not work on attributes in JSONAPI:Resources 0.9 by default.
      # This can be removed as soon as we update to 0.10, which is currently only in alpha

      def self.creatable_fields(context)
        super - _attributes.select { |_attr, options| options[:readonly] }.keys -
          _relationships.select { |_rel_key, rel| rel.options[:readonly] }.keys
      end

      def self.updatable_fields(context)
        super - _attributes.select { |_attr, options| options[:readonly] || options[:write_once] }.keys -
          _relationships.select { |_rel_key, rel| rel.options[:readonly] || rel.options[:write_once] }.keys
      end

      def fetchable_fields
        super - self.class._attributes.select { |_attr, options| options[:writeonly] }.keys -
          self.class._relationships.select { |_rel_key, rel| rel.options[:writeonly] }.keys
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
      def self.apply_includes(records, options = {})
        if @default_includes.present?
          super(records.preload(*inclusions), options)
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
          return model_includes.map { |value| resolve_relationship_names_to_relations(resource_klass, value, options) }
        when Hash
          model_includes.keys.each do |key|
            relationship = resource_klass._relationships[key]
            value = model_includes[key]
            model_includes.delete(key)

            # MODIFICATION BEGINS
            included_relationships =
              resolve_relationship_names_to_relations(relationship.resource_klass, value, options)
            model_includes[relationship.relation_name(options)] = relationship.resource_klass.inclusions +
              included_relationships
            # MODIFICATION ENDS
          end
          return model_includes
        when Symbol
          relationship = resource_klass._relationships[model_includes]

          # MODIFICATION BEGINS
          # return relationship.relation_name(options)
          inclusions = relationship.resource_klass.inclusions
          { relationship.relation_name(options) => inclusions }
          # MODIFICATION ENDS
        end
      end
      # rubocop:enable all
    end
  end
end
