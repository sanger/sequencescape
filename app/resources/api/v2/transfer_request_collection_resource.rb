# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TransferRequestCollection}
    #
    # A {TransferRequestCollection} provides a means of bulk creating transfer requests between arbitrary
    # sources and destinations.
    # This resource allows the creation of a collection of transfer requests in a single
    # transaction, avoiding multiple server calls for each transfer request.
    #
    # @note Access this resource via the `/api/v2/transfer_request_collections/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # @example POST request to create a TransferRequestCollection with multiple transfer requests
    #   POST /api/v2/transfer_request_collections/
    #   {
    #     "data": {
    #       "type": "transfer_request_collections",
    #       "attributes": {
    #         "transfer_requests_attributes": [
    #           {
    #             "source_asset": "dc33e42e-f5e1-11ef-98fe-000000000000",
    #             "target_asset": "de19e8e2-f5e1-11ef-98fe-000000000000",
    #             "aliquot_attributes": {
    #               "tag_depth": "2"
    #             }
    #           },
    #           {
    #             "source_asset": "44444444-5555-6666-7777-888888999999",
    #             "target_asset": "55555555-6666-7777-8888-999999000000",
    #             "aliquot_attributes": {
    #               "tag_depth": "3"
    #             }
    #           }
    #         ]
    #       },
    #       "relationships": {
    #         "user": {
    #           "data": {
    #             "type": "users",
    #             "id": 4
    #           }
    #         }
    #       }
    #     }
    #   }
    #
    # @example GET request for all TransferRequestCollection resources
    #   GET /api/v2/transfer_request_collections/
    #
    # @example GET request for a TransferRequestCollection with ID 123
    #   GET /api/v2/transfer_request_collections/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TransferRequestCollectionResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] transfer_requests_attributes
      #   To enable the creation of {TransferRequest} records server side in a single transaction, the attributes
      #   for transfer requests to be included in the collection can be passed as an array of hashes. These will be
      #   created at the same time as the {TransferRequestCollection} to avoid making multiple server calls.
      #
      #   @example Hashes should contain the following data about each transfer request
      #     {
      #       'source_asset': 'The UUID of the source asset as a string.',
      #       'target_asset': 'The UUID of the destination asset as a string.',
      #       'aliquot_attributes': {
      #         'tag_depth': 'The tag depth of the source as a string.'
      #       }
      #     }
      #
      #   @param value [Array<Hash>] An array of hashes, where each hash contains the attributes for a transfer request.
      #   @return [Void]
      #   @deprecated Use the `transfer_requests` relationship instead.
      #   @see #transfer_requests
      attribute :transfer_requests_attributes, writeonly: true

      def transfer_requests_attributes=(value)
        return if value.nil?

        # Convert ActionController::Parameters into hashes.
        @model.transfer_requests_io = value.map(&:to_unsafe_h)
      end

      # @!attribute [w] user_uuid
      #   Declared for convenience when the user is not available to set as a relationship.
      #   @deprecated Use the `user` relationship instead.
      #     See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @param value [String] The UUID of the user who initiated the creation of this transfer request collection.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the transfer request collection.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] target_tubes
      #   @return [Array<TubeResource>] An array of tubes that are the targets for the transfer requests
      #   in this collection.
      has_many :target_tubes, class_name: 'Tube', readonly: true

      # @!attribute [r] transfer_requests
      #   @return [Array<TransferRequestResource>] An array of transfer requests within this collection.
      has_many :transfer_requests, readonly: true

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The user who initiated the creation of this transfer request collection.
      #   @note This relationship is required.
      has_one :user
    end
  end
end
