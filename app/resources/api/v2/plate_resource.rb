# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Plate} which is plastic labware containing {Well}s.
    # The plate has a purpose like all labware and this denotes which pipeline it is being used in and what type of
    # samples it holds / how it will be processed.
    # Plates are not typically created directly using this resource, although they can be.
    # Rather they are created via resources such as {PlateCreationResource}.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/plates/` endpoint.
    #
    # @example POST request
    #   POST /api/v2/plates/
    #   {
    #     "data": {
    #       "type": "plates",
    #       "attributes": {
    #         "size": 96
    #       },
    #       "relationships": {
    #         "purpose": {
    #           "data": { "type": "purposes", "id": "123" }
    #         },
    #         "wells": [
    #           { "data": { "type": "wells", "id": "456" } },
    #           { "data": { "type": "wells", "id": "789" } }
    #         ],
    #       }
    #     }
    #   }
    #
    # @example GET request for all Plate resources
    #   GET /api/v2/plates/
    #
    # @example GET request for a Plate with ID 123
    #   GET /api/v2/plates/123/
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

      # TODO: {Y24-213} Possibly this line doesn't actually do anything and could be removed.
      default_includes :uuid_object, :barcodes, :plate_purpose, :transfer_requests

      ###
      # Attributes
      ###

      # @!attribute [r] number_of_rows
      #   @return [Int] The number of rows on the plate.
      #     This is determined by the {AssetShape} assigned to the plate by its purpose.
      attribute :number_of_rows, readonly: true, delegate: :height

      # @!attribute [r] number_of_columns
      #   @return [Int] The number of columns on the plate.
      #     This is determined by the {AssetShape} assigned to the plate by its purpose.
      attribute :number_of_columns, readonly: true, delegate: :width

      # @!attribute [rw] size
      #   @note This can only be set once during creation.
      #     If it is not set, it will default to 96.
      #   @return [Int] The total number of wells on the plate.
      attribute :size, write_once: true

      # @!attribute [r] pooling_metadata
      #   @example Hash representation
      #     {
      #       "12345678-1234-1234-1234-1234567890ab": {
      #         "wells": ["A1", "A2", "A3"],
      #         "pool_complete": true,
      #         "insert_size": { "from": 1, "to": 1 },
      #         "library_type": { "name": "Bioscan" },
      #         "pcr_cycles": 0,
      #         "request_type": "limber_bioscan_library_prep",
      #         "for_multiplexing": false
      #       },
      #       "87654321-4321-4321-4321-ba0987654321": {
      #         "wells": ["B1", "B2", "B3"],
      #         "pool_complete": true,
      #         "insert_size": { "from": 1, "to": 1 },
      #         "library_type": { "name": "Bioscan" },
      #         "pcr_cycles": 0,
      #         "request_type": "limber_bioscan_library_prep",
      #         "for_multiplexing": false
      #       }
      #     }
      #   @return [Hash] A hash containing submission UUIDs and corresponding pooling metadata.
      attribute :pooling_metadata, readonly: true

      def pooling_metadata
        _model.pools
      end

      ###
      # Relationships
      ###

      # @!attribute [r] submission_pools
      #   @return [Array<SubmissionPoolResource>] An array of submission pools for this plate.
      has_many :submission_pools, readonly: true

      # @!attribute [r] transfers_as_destination
      #   @return [Array<TransferResource>] An array of transfers with this plate as the destination.
      has_many :transfers_as_destination, readonly: true

      # @!attribute [rw] wells
      #   @note This can only be set once during creation.
      #   @return [Array<WellResource>] An array of wells on this plate.
      has_many :wells, write_once: true
    end
  end
end
