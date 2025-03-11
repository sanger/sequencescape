# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TransferRequest}.
    #
    # A `TransferRequest` represents a request for transferring ("moving") a resource (asset) from one
    #   location to another
    # without really transforming it (chemically) as, cherrypicking, pooling, spreading on the floor etc
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/transfer_requests/` endpoint.
    #
    # @example GET request for all TransferRequest resources
    #   GET /api/v2/transfer_requests/
    #
    # @example GET request for a TransferRequest with ID 123
    #   GET /api/v2/transfer_requests/123/
    #
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TransferRequestResource < BaseResource
      immutable

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   The unique identifier of the transfer request.
      #   @return [String] The UUID of the transfer request.
      attribute :uuid, readonly: true

      # @!attribute [r] state
      #   The current state of the transfer request, indicating its processing status (e.g., pending, completed).
      #   @return [String] The state of the transfer request.
      attribute :state, readonly: true

      # @!attribute [r] volume
      #   The volume associated with the transfer request. This could represent the quantity of material
      #     to be transferred.
      #   @return [Integer] The volume of the transfer request.
      attribute :volume, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] source_asset
      #   The source asset (or receptacle) from which the material is being transferred.
      #   @return [ReceptacleResource] The source asset related to the transfer request.
      has_one :source_asset, relation_name: 'asset', foreign_key: :asset_id, class_name: 'Receptacle', readonly: true

      # @!attribute [r] submission
      #   The submission associated with this transfer request, which provides context for the transfer.
      #   @return [SubmissionResource] The submission related to the transfer request.
      has_one :submission, foreign_key: :submission_id, class_name: 'Submission', readonly: true

      # @!attribute [r] target_asset
      #   The target asset (or receptacle) to which the material is being transferred.
      #   @return [ReceptacleResource] The target asset related to the transfer request.
      has_one :target_asset, foreign_key: :target_asset_id, class_name: 'Receptacle', readonly: true
    end
  end
end
