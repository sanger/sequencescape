# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {BulkTransfer} which allows the transfer of multiple wells from source
    # plates to destination plates. The plates and wells to transfer are specified using {#well_transfers=}.
    # Creation of this resource via a `POST` request will perform the specified transfers.
    # After creation, the transfers can be accessed via the {#transfers} relationship.
    #
    # @note Access this resource via the `/api/v2/bulk_transfers/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # @example POST request with user specified by relationship
    #   POST /api/v2/bulk_transfers/
    # {
    #   "data": {
    #     "type": "bulk_transfers",
    #     "attributes": {
    #       "well_transfers": [
    #         {
    #           "source_uuid": "7b4c094a-fe6d-11ef-ba74-000000000000",
    #           "source_location": "A2",
    #           "destination_uuid": "7b4c094a-fe6d-11ef-ba74-000000000000",
    #           "destination_location": "A2"
    #         }
    #       ]
    #     },
    #     "relationships": {
    #       "user": {
    #         "data": {
    #           "type": "users",
    #           "id": 4
    #         }
    #       }
    #     }
    #   }
    # }
    #
    # @example GET request for all BulkTransfer resources
    #   GET /api/v2/bulk_transfers/
    #
    # @example GET request for a BulkTransfer with ID 123
    #   GET /api/v2/bulk_transfers/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class BulkTransferResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the user who initiated the creation of the bulk transfers.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the bulk transfers operation.
      attribute :uuid, readonly: true

      # @!attribute [w] well_transfers
      #   An array of well transfers to perform. Each transfer is a hash with the following:
      #
      #   - `source_uuid` [String] The UUID of the source plate.
      #   - `source_location` [String] The location on the source plate.
      #   - `destination_uuid` [String] The UUID of the destination plate.
      #   - `destination_location` [String] The location on the destination plate.
      #
      #   @return [Void]
      attribute :well_transfers, writeonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] transfers
      #   The transfers that were created as a result of this bulk transfer.
      #   @return [Array<TransferResource>] An array of created transfers.
      has_many :transfers, readonly: true

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The user who initiated the creation of the bulk transfers.
      #   @note This relationship is required.
      has_one :user
    end
  end
end
