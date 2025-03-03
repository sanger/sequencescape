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
    end
  end
end
