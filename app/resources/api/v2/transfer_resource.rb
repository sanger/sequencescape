# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Transfer}.
    #
    # A transfer handles the transfer of material from one piece of labware to another.
    # Different classes are used to determine exactly how the transfers are performed.
    # @note {TransferRequestCollection} is preferred, as it allows the client applications to control
    #       the transfer behaviour.
    #
    # @note Access this resource via the `/api/v2/transfers/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # @example POST request for creating a new transfer with source and destination specified by UUID (deprecated)
    #   POST /api/v2/transfers/
    #   {
    #     "data": {
    #       "type": "transfers",
    #       "attributes": {
    #         "source_uuid": "11111111-2222-3333-4444-555555666666",
    #         "destination_uuid": "33333333-4444-5555-6666-777777888888",
    #         "user_uuid": "99999999-0000-1111-2222-333333444444"
    #       }
    #     }
    #   }
    #
    # @example POST request for creating a transfer with source and destination specified by relationships
    #   POST /api/v2/transfers/
    # {
    #   "data": {
    #     "type": "transfers",
    #     "attributes": {
    #       "transfer_template_uuid": "9ab465da-7cdf-11ef-b4cc-000000000000"
    #     },
    #     "relationships": {
    #       "source": { "data": { "type": "labware", "id": 1 } },
    #       "destination": { "data": { "type": "labware", "id": 2 } },
    #       "user": { "data": { "type": "users", "id": "789" } }
    #     }
    #   }
    # }
    #
    # @example GET request for retrieving all transfers
    #   GET /api/v2/transfers/
    #
    # @example GET request for a specific transfer with ID 123
    #   GET /api/v2/transfers/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or refer to the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TransferResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   The UUID of the transfer.
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the transfer.
      attribute :uuid, readonly: true

      # @!attribute [rw] transfers
      #   A hash of transfers made, usually populated by a TransferTemplate used during the creation of the Transfer.
      #   This method varies depending on the type of transfer being performed.
      #   @return [Hash] A hash of transfer details.
      attribute :transfers

      def transfers
        # Only some transfer types have the :transfers method.
        # This gets implemented differently, depending on the type of transfer being performed.
        return nil unless @model.respond_to?(:transfers)

        @model.transfers
      end

      def transfers=(transfers)
        # This setter is invoked by TransferTemplate to populate the transfers attribute.
        @model.transfers =
          if transfers.is_a?(ActionController::Parameters)
            transfers.to_unsafe_h # Convert parameters to a hash.
          else
            transfers
          end
      end

      # @!attribute [r] transfer_type
      #   The STI (Single Table Inheritance) type of the transfer.
      #   @return [String] The transfer type.
      attribute :transfer_type, delegate: :sti_type, readonly: true

      # @!attribute [w] transfer_template_uuid
      #   The UUID of a TransferTemplate to create a transfer from.
      #   @note This is a required field.
      #   @param value [String] The UUID of the TransferTemplate.
      #   @return [Void]
      attribute :transfer_template_uuid, writeonly: true
      attr_writer :transfer_template_uuid # This is consumed by the transfers_controller and not stored in the model.

      ###
      # Deprecated Attributes
      ###

      # @!attribute [rw] destination_uuid
      #   This attribute allows the user to specify the destination labware by UUID.
      #   @deprecated Use the `destination` relationship instead.
      #   Setting this attribute alongside the `destination` relationship will prefer the relationship value.
      #   @return [String, Void] the UUID of the destination labware.
      #   @see #destination
      attribute :destination_uuid

      def destination_uuid
        @model.destination&.uuid
      end

      def destination_uuid=(uuid)
        @model.destination = Labware.with_uuid(uuid).first if uuid
      end

      # @!attribute [rw] source_uuid
      #   This attribute allows the user to specify the source labware by UUID.
      #   @deprecated Use the `source` relationship instead.
      #   Setting this attribute alongside the `source` relationship will prefer the relationship value.
      #   @return [Void]
      #   @see #source
      attribute :source_uuid

      def source_uuid
        @model.source.uuid
      end

      def source_uuid=(uuid)
        @model.source = Labware.with_uuid(uuid).first
      end

      # @!attribute [rw] user_uuid
      #   This attribute is declared for convenience where the user is not available to set as a relationship.
      #   @deprecated Use the `user` relationship instead.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, write_once: true

      def user_uuid
        @model.user&.uuid # Some old records may not have a User relationship, even though it's required for new records.
      end

      def user_uuid=(uuid)
        @model.user = User.with_uuid(uuid).first
      end

      ###
      # Custom Methods for Creation
      ###

      def self.create(context)
        new(context[:model_type].new, context)
      end

      ###
      # Relationships
      ###

      # @!attribute [rw] destination
      #   The destination labware for the transfer.
      #   Setting this relationship alongside the `destination_uuid` attribute will override the attribute value.
      #   @return [LabwareResource, Void]
      has_one :destination

      # @!attribute [rw] source
      #   The source labware for the transfer. The type of the labware varies by the transfer type.
      #   Setting this relationship alongside the `source_uuid` attribute will override the attribute value.
      #   @note This relationship is required.
      #   @return [LabwareResource]
      has_one :source, class_name: 'Labware'

      # @!attribute [rw] user
      #   The user who requested the transfer.
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @note This relationship is required.
      #   @return [UserResource]
      has_one :user

      ###
      # Filters
      ###

      # @!method transfer_type
      #   A filter to restrict the type of transfer to retrieve.
      #   Example usage:
      #   GET /api/v2/transfers?filter[transfer_type]=Transfer::BetweenPlates
      #   One of the following types:
      #     - 'Transfer::BetweenPlateAndTubes'
      #     - 'Transfer::BetweenPlatesBySubmission'
      #     - 'Transfer::BetweenPlates'
      #     - 'Transfer::BetweenSpecificTubes'
      #     - 'Transfer::BetweenTubesBySubmission'
      #     - 'Transfer::FromPlateToSpecificTubesByPool'
      #     - 'Transfer::FromPlateToSpecificTubes'
      #     - 'Transfer::FromPlateToTubeByMultiplex'
      #     - 'Transfer::FromPlateToTubeBySubmission'
      #     - 'Transfer::FromPlateToTube'
      filter :transfer_type, apply: ->(records, value, _options) { records.where(sti_type: value) }
    end
  end
end
