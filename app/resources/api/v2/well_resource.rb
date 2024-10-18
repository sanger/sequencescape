# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/wells/` endpoint.
    #
    # Provides a JSON:API representation of {Well}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class WellResource < BaseResource
      include Api::V2::SharedBehaviour::Receptacle

      # Constants...

      default_includes :uuid_object, :map, :transfer_requests_as_target, plate: :barcodes

      # Associations:

      # Attributes
      attribute :position, write_once: true

      # Custom methods

      def position
        { 'name' => _model.map_description }
      end

      # Class method overrides
    end
  end
end
