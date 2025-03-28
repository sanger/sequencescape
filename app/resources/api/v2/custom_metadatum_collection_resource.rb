# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {CustomMetadatumCollection}, which represents a collection
    # of metadata associated with a specific asset (such as Labware).
    #
    # This resource allows clients to store, retrieve, and manage metadata associated with a specific asset.
    #
    # @note Access this resource via the `/api/v2/custom_metadatum_collections/` endpoint.
    #
    # @example Creating a CustomMetadatumCollection via a POST request
    #   POST /api/v2/custom_metadatum_collections/
    #   {
    #     "data": {
    #         "type": "custom_metadatum_collections",
    #         "attributes": {
    #             "user_id": 1,
    #             "asset_id": 1,
    #             "metadata": {
    #                 "key": "a value againnnn"
    #             }
    #         },
    #         "relationships": {}
    #     }
    #   }
    #
    # @example Updating a specific CustomMetadatumCollection via a PATCH request
    #   PATCH /api/v2/custom_metadatum_collections/123
    #   {
    #     "data": {
    #         "id": 6,
    #         "type": "custom_metadatum_collections",
    #         "attributes": {
    #             "metadata": {
    #                 "key1": "value3"
    #             }
    #         }
    #     }
    #   }
    #
    # @example Retrieving a specific CustomMetadatumCollection by ID
    #   GET /api/v2/custom_metadatum_collections/123
    #
    # @example Retrieving all CustomMetadatumCollections
    #   GET /api/v2/custom_metadatum_collections/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class CustomMetadatumCollectionResource < BaseResource
      default_includes :uuid_object, :custom_metadata

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the collection. This uniquely identifies the metadata collection.
      attribute :uuid, readonly: true

      # @!attribute [rw] user_id
      #   @note This field is required.
      #   @note This attribute is write_once; this attribute cannot be updated.
      #   @todo deprecate; use the `user` relationship instead
      #   @return [Integer] The ID of the user who created this collection.
      attribute :user_id, write_once: true

      # @!attribute [rw] asset_id
      #   @note This field is required.
      #   @note This attribute is write_once; this attribute cannot be updated.
      #   @todo deprecate; use the `user` relationship instead
      #   @return [Integer] The ID of the labware asset that this metadata collection corresponds to.
      attribute :asset_id, write_once: true

      # @!attribute [rw] metadata
      #   @return [Hash] A key-value store of metadata entries associated with this collection.
      attribute :metadata
    end
  end
end
