# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/lots/` endpoint.
    #
    # Provides a JSON:API representation of {Lot}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class LotResource < BaseResource
      # Constants...

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:
      has_one :lot_type
      has_one :user
      has_one :template, polymorphic: true
      has_one :tag_layout_template, eager_load_on_include: false

      # Attributes
      attribute :uuid, readonly: true
      attribute :lot_number, write_once: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.
      def tag_layout_template_id
        template_id
      end

      # Class method overrides
    end
  end
end
