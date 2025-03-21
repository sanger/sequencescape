# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {PolyMetadatum}.
    #
    # A `PolyMetadatum`  is a key value pair store. It is set up such that it can be
    # associated with multiple different models (ie. a polymorphic relationship).
    #
    # @note This resource is accessed via the `/api/v2/poly_metadata/` endpoint.
    #
    # @example GET request to retrieve all poly metadata
    #   GET /api/v2/poly_metadata/
    #
    # @example POST request to create a new metadata entry
    #   POST /api/v2/poly_metadata/
    #   {
    #     "data": {
    #       "type": "pooled_plate_creations",
    #       "attributes": {
    #         "child_purpose_uuid": ["f64dec80-f51c-11ef-8842-000000000000"]
    #       },
    #       "relationships": {
    #         // "child_purpose": {
    #         //   "data": { "type": "purposes", "id": "uuid-of-child-purpose" }
    #         // },
    #         "parents": {
    #           "data": [
    #             { "type": "labware", "id": 1 },
    #             { "type": "labware", "id": 4 }
    #           ]
    #         },
    #         "user": {
    #           "data": { "type": "users", "id": 1 }
    #         }
    #       }
    #     }
    #   }
    #
    # @example PATCH request to update an existing metadata entry
    #   PATCH /api/v2/poly_metadata/123
    #   {
    #     "data": {
    #       "id": "123",
    #       "type": "poly_metadata",
    #       "attributes": {
    #         "value": "RNA"
    #       }
    #     }
    #   }
    #

    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class PolyMetadatumResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [rw] key
      #   The key or name of the metadata.
      #   @note This is a required attribute and must be unqiue for each metadatable object.
      #   @return [String] The metadata key.
      attribute :key

      # @!attribute [rw] value
      #   The value stored under the metadata key.
      #   @note This is a required attribute
      #   @return [String] The metadata value.
      attribute :value

      # @!attribute [r] created_at
      #   The timestamp indicating when this metadata entry was created.
      #   @return [DateTime] The creation time of the metadata record.
      attribute :created_at, readonly: true

      # @!attribute [r] updated_at
      #   The timestamp indicating when this metadata entry was last updated.
      #   @return [DateTime] The last modification time of the metadata record.
      attribute :updated_at, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] metadatable
      #   The resource that this metadata belongs to.
      #   This is a polymorphic association, it can be associated with multiple different models
      #     (e.g., {Well}, {Sample}).
      #   @note This is a required relationship.
      #   @note The given metadata must exist
      #   @return [ApplicationRecord] The associated record.
      has_one :metadatable, polymorphic: true

      ###
      # Filters
      ###

      # @!method filter_by_key
      #   Filters metadata records based on their key.
      #   @example GET request to retrieve metadata with a specific key
      #     GET /api/v2/poly_metadata?filter[key]=sample_type
      filter :key

      # @!method filter_by_metadatable_id
      #   Filters metadata records based on the associated resource's ID.
      #   @example GET request to retrieve metadata associated with a specific resource
      #     GET /api/v2/poly_metadata?filter[metadatable_id]=123
      filter :metadatable_id
    end
  end
end
