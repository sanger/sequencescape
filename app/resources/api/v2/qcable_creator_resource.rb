# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {QcableCreator} which represents ...
    #
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    # @note Access this resource via the `/api/v2/qcable_creators/` endpoint.
    #
    #
    # @example POST request to create a {QcableCreator}.
    # TODO: Add example of creating a QcableCreator with barcodes and count.
    #   POST /api/v2/qcable_creators/
    #   {
    #     "data": {
    #       "type": "qcable_creators",
    #       "attributes": {
    #       },
    #      "relationships": {
    #         "lot": {
    #           "data": { "type": "lots", "id": 1 }
    #         },
    #         "user": {
    #           "data": { "type": "users", "id": 1 }
    #         }
    #       }
    #     }
    #   }
    # }
    #
    # @example GET request for all {QcableCreator} resources
    #   GET /api/v2/qcable_creators/
    #
    # @example GET request for a {QcableCreator} with ID 123
    #   GET /api/v2/qcable_creators/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class QcableCreatorResource < BaseResource
      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @return [String] the UUID of this {QcableCreator}.
      attribute :uuid, readonly: true

      # @!attribute [rw] barcodes
      #   Either this or 'count' is passed in when creating a {QcableCreator}.
      #   @return [Array<String>] the barcodes to use when creating the associated {Qcable}s.
      attribute :barcodes

      # @!attribute [rw] count
      #   Either this or 'barcodes' is passed in when creating a {QcableCreator}.
      #   @return [Integer] the number of {Qcable}s to create under this {QcableCreator}.
      attribute :count

      ###
      # Relationships
      ###

      # @!attribute [rw] lot
      #   @return [LotResource] the {Lot} resource associated with this {QcableCreator}.
      has_one :lot

      # @!attribute [rw] user
      #   @return [UserResource] the {User} resource associated with this {QcableCreator}.
      has_one :user

      # @!attribute [r] qcables
      #   @return [Array<QcableResource>] the {Qcable} resources created by this {QcableCreator}.
      has_many :qcables, read_only: true

      ###
      # Filters
      ###

      # @!method filter_uuid
      #   Apply a filter across all {QcableCreator} resources, matching by UUID.
      #   @example Get all {QcableCreator} resources with a specific UUID.
      #     /api/v2/qcable_creators?filter[uuid]=12345678-1234-1234-1234-123456789012
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
    end
  end
end
