# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/plates/` endpoint.
    #
    # Provides a JSON:API representation of {Plate}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class PlateResource < BaseResource
      # We import most labware shared behaviour, this includes associations,
      # attributes and filters
      # Before adding behaviour here, consider if they can be applied to ALL
      # labware
      include Api::V2::SharedBehaviour::Labware

      # Constants...

      default_includes :uuid_object, :barcodes, :plate_purpose, :transfer_requests

      # Associations:
      has_many :submission_pools, readonly: true
      has_many :wells, write_once: true

      # Attributes
      attribute :number_of_rows, write_once: true, delegate: :height
      attribute :number_of_columns, write_once: true, delegate: :width
      attribute :size, write_once: true
      attribute :pooling_metadata, readonly: true

      def pooling_metadata
        _model.pools
      end

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
