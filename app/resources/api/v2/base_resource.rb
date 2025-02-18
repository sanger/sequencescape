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
    end
  end
end
