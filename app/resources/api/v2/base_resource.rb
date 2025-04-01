# frozen_string_literal: true

module Api
  module V2
    # @api V2
    # @abstract
    #
    # Provides a base class for JSON:API representations of {ApplicationRecord} sub-classes.
    # This class extends `JSONAPI::Resource` and serves as the foundation for all API v2 resources.
    #
    # ## Key Features:
    # - Implements JSON:API standard resource handling.
    # - Provides global model hints for common resource models.
    # - Defines attribute and relationship access restrictions (`readonly`, `write_once`, `writeonly`).
    # - Customizes the creatable, updatable, and fetchable fields logic.
    #
    # @note This class is abstract and should not be instantiated directly.
    # @note For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    #   or refer to the [JSONAPI::Resources](http://jsonapi-resources.com/) package.
    class BaseResource < JSONAPI::Resource
      # Marks this class as abstract, preventing direct instantiation.
      abstract

      ###
      # Model Hints
      ###
      # These hints provide global model-resource mappings for commonly used models.
      # They allow JSONAPI::Resources to infer relationships and attributes.
      Order.descendants.each { |subclass| model_hint model: subclass, resource: :order }
      Purpose.descendants.each { |subclass| model_hint model: subclass, resource: :purpose }
      Plate.descendants.each { |subclass| model_hint model: subclass, resource: :plate }
      Tube.descendants.each { |subclass| model_hint model: subclass, resource: :tube }
      Request.descendants.each { |subclass| model_hint model: subclass, resource: :request }
      Transfer.descendants.each { |subclass| model_hint model: subclass, resource: :transfer }

      ###
      # Attribute and Relationship Access Control
      ###
      # This class extends JSON:API::Resources to support the following field access restrictions:
      # - `readonly`: The attribute/relationship can be read but not written to.
      # - `write_once`: The attribute/relationship can be written only during creation but not updated.
      # - `writeonly`: The attribute/relationship can be written to but not read.
      #
      # These modifications avoid the need to override `self.creatable_fields`, `self.updatable_fields`,
      # and `fetchable_fields` in every derived resource.
      #
      # @note The `readonly` restriction does not work on attributes in JSONAPI::Resources 0.9 by default.
      #   This limitation will be removed once we upgrade to version 0.10.

      ###
      # Class Methods
      ###

      # Determines which fields can be set when creating a new resource.
      #
      # @param context [Object] The request context, used to determine access permissions.
      # @return [Set<Symbol>] A set of attributes and relationships that can be written when creating a resource.
      def self.creatable_fields(context)
        super - _attributes.select { |_attr, options| options[:readonly] }.keys -
          _relationships.select { |_rel_key, rel| rel.options[:readonly] }.keys
      end

      # Determines which fields can be updated after a resource has been created.
      #
      # @param context [Object] The request context, used to determine access permissions.
      # @return [Set<Symbol>] A set of attributes and relationships that can be modified after creation.
      def self.updatable_fields(context)
        super - _attributes.select { |_attr, options| options[:readonly] || options[:write_once] }.keys -
          _relationships.select { |_rel_key, rel| rel.options[:readonly] || rel.options[:write_once] }.keys
      end

      ###
      # Instance Methods
      ###

      # Determines which fields can be read when fetching a resource.
      #
      # @return [Set<Symbol>] A set of attributes and relationships that can be retrieved.
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
