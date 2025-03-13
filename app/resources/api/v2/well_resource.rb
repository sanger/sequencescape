# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Well}.
    #
    # A Well is a {Receptacle} on a {Plate}, it can contain one or more {Aliquot aliquots}.
    # A plate may have multiple wells, with the two most common sizes being 12*8 (96) and
    # 24*26 (384). The wells are differentiated via their {Map} which corresponds to a
    # row and column. Most well locations are identified by a letter-number combination,
    # eg. A1, H12.
    #
    # Access this resource via the `/api/v2/wells/` endpoint.
    #
    # @example GET request for all Wells
    #   GET /api/v2/wells/
    #
    # @example GET request for a Well with ID 123
    #   GET /api/v2/wells/123/
    #
    # @note Well attributes here are defined in {Api::V2::SharedBehaviour::Receptacle}
    # @example POST request to create a new Well
    #   POST /api/v2/wells/
    # {
    #   "data": {
    #     "type": "wells",
    #     "attributes": {
    #           "pcr_cycles": 12,
    #         "submit_for_sequencing": false,
    #         "sub_pool": 2,
    #         "coverage": 50,
    #         "diluent_volume": 34.0
    #     },
    #     "relationships": {
    #       "poly_metadata": {
    #         "data": [{ "type": "poly_metadata", "id": 10 }]
    #       }
    #     }
    #   }
    # }
    #
    # @example PATCH request to update metadata for a Well
    #   PATCH /api/v2/wells/123/
    #   {
    #     "data": {
    #       "type": "wells",
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
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class WellResource < BaseResource
      # Api::V2::SharedBehaviour::Receptacle provides common functionality, methods and relationships
      include Api::V2::SharedBehaviour::Receptacle

      default_includes :uuid_object, :map, :transfer_requests_as_target, plate: :barcodes

      ###
      # Attributes
      ###

      # @!attribute [r] position
      #   The position of the well within the labware. This is typically a string representing the well's
      #   position (e.g., 'A1', 'B12'). This attribute is read-only and cannot be modified.
      #
      #   @return [Hash] A hash containing the position name and additional details.
      #   @note This field is automatically populated based on the well's location within the labware.
      attribute :position, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] poly_metadata
      #   @return [PolyMetadatumResource] The associated metadata for the well.
      #   @note This is a one-to-many relationship, where a well can have multiple pieces of metadata.
      #   @note The `poly_metadata` must already exist in the database before it can be associated with a Well.
      #   @see PolyMetadatumResource
      has_many :poly_metadata, as: :metadatable, class_name: 'PolyMetadatum'

      ###
      # Methods
      ###

      # @!method position
      #   @return [Hash] Returns the position of the well as a hash. The hash includes details such as
      #           the well's map description.
      def position
        { 'name' => _model.map_description }
      end
    end
  end
end
