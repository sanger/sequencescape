# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/transfer_request_collections/` endpoint.
    #
    # Provides a JSON:API representation of {TransferRequestCollection}.
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
      #   @param value [Array<Hash>] An array of hashes containing the attributes for transfer request to be created.
      #   @return [Void]
      #   @see #transfer_requests
      attribute :transfer_requests_attributes, writeonly: true

      def transfer_requests_attributes=(value)
        return if value.nil?

        # Convert ActionController::Parameters into hashes.
        @model.transfer_requests_io = value.map(&:to_unsafe_h)
      end

      # @!attribute [w] user_uuid
      #   This is declared for convenience where the user is not available to set as a relationship.
      #   Setting this attribute alongside the `user` relationship will prefer the relationship value.
      #   @deprecated Use the `user` relationship instead.
      #   @param value [String] The UUID of the user who initiated the creation of this pooled plate.
      #   @return [Void]
      #   @see #user
      attribute :user_uuid, writeonly: true

      def user_uuid=(value)
        @model.user = User.with_uuid(value).first
      end

      # @!attribute [r] uuid
      #   @return [String] The UUID of the state change.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] target_tubes
      #   @return [Array<TubeResource>] An array of tubes targeted by the transfer requests in this collection.
      has_many :target_tubes, class_name: 'Tube', readonly: true

      # @!attribute [r] transfer_requests
      #   @return [Array<TransferRequestResource>] An array of transfer requests in this collection.
      has_many :transfer_requests, readonly: true

      # @!attribute [rw] user
      #   Setting this relationship alongside the `user_uuid` attribute will override the attribute value.
      #   @return [UserResource] The user who initiated the creation of the pooled plate.
      #   @note This relationship is required.
      has_one :user
    end
  end
end
