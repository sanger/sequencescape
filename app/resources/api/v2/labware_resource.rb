# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Labware} to access all labware objects,
    # which includes plates and tubes. When creating Labware, do so via the {PlateResource}
    # or {TubeResource} instead.
    #
    # @note Access this resource via the `/api/v2/labware/` endpoint.
    #
    # @example GET request for all Labware resources
    #   GET /api/v2/labware/
    #
    # @example GET request for a single Labware resource with ID 123
    #   GET /api/v2/labware/123/
    #
    # @example POST request to create a new Labware resource
    #   POST /api/v2/labware/
    #   {
    #     "data": {
    #       "type": "labware",
    #       "attributes": {
    #       },
    #       "relationships": {
    #         "poly_metadata": {
    #           "data": [{ "type": "poly_metadata", "id": 10 }]
    #         }
    #       }
    #     }
    #   }
    #
    #
    # @example PATCH request to update metadata for a Labware
    #   PATCH /api/v2/labware/123/
    #   {
    #     "data": {
    #       "type": "labware",
    #       "id": "123",
    #       "relationships": {
    #         "poly_metadata": {
    #           "data": [{ "type": "poly_metadata", "id": "456" }]
    #         }
    #       }
    #     }
    #   }
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out [JSONAPI::Resources](http://jsonapi-resources.com/) for Sequencescape's implementation.
    class LabwareResource < BaseResource
      # We import most labware shared behaviour, including associations,
      # attributes, and filters. This ensures that labware-specific behaviour
      # is automatically available on plates and tubes.
      include Api::V2::SharedBehaviour::Labware

      default_includes :uuid_object, :barcodes

      # @!attribute [r] poly_metadata
      #   @return [PolyMetadatumResource] The associated metadata for the Labware.
      #   @note This is a one-to-many relationship, where a Labware can have multiple pieces of metadata.
      #   @note The `poly_metadata` must already exist in the database before it can be associated with a Labware.
      #   @see PolyMetadatumResource
      has_many :poly_metadata, as: :metadatable, class_name: 'PolyMetadatum'

      ###
      # Custom Methods
      ###

      # Returns a hash containing different barcode types associated with the labware.
      #   @return [Hash] A hash with keys for each barcode type and their corresponding values.
      def labware_barcode
        {
          'ean13_barcode' => _model.try(:ean13_barcode),
          'machine_barcode' => _model.try(:machine_barcode),
          'human_barcode' => _model.try(:human_barcode)
        }
      end
    end
  end
end
