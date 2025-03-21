# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Qcable} which represents an element of a lot which needs to be approved
    # by QC before it can be used.
    #
    # @note Access this resource via the `/api/v2/qcables/` endpoint.
    #
    # @example POST request to create a {Qcable}.
    #   POST /api/v2/qcables/
    #   {
    #     "data": {
    #       "type": "qcables",
    #       "attributes": {
    #       },
    #       "relationships": {
    #         "labware": {
    #           "data": { "type": "labware", "id": 57 }
    #         },
    #         "lot": {
    #           "data": { "type": "lots", "id": 1 }
    #         }
    #       }
    #     }
    #   }
    #
    # @example PATCH request to change the {Asset} of a {Qcable}.
    #   PATCH /api/v2/qcables/
    #   {
    #     "data": {
    #       "type": "qc_files",
    #       "id": 123
    #       "relationships": {
    #         "asset": {
    #           "data": {
    #             "type": "labware",
    #             "id": 456
    #           }
    #         }
    #       }
    #     }
    #   }
    #
    # @example GET request for all {Qcable} resources
    #   GET /api/v2/qcables/
    #
    # @example GET request for a {Qcable} with ID 123
    #   GET /api/v2/qcables/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class QcableResource < BaseResource
      default_includes :uuid_object, :barcodes

      ###
      # Attributes
      ###

      # @!attribute [r] labware_barcode
      #   @return [Hash] the barcodes of the labware associated with this {Qcable}.
      #     This includes the EAN13 barcode, the machine barcode and the human barcode.
      #     Note however that some of these barcodes may be `nil`.
      attribute :labware_barcode, readonly: true
      def labware_barcode
        {
          'ean13_barcode' => @model.ean13_barcode,
          'machine_barcode' => @model.machine_barcode,
          'human_barcode' => @model.human_barcode
        }
      end

      # @!attribute [r] state
      #   @return [String] a string representation of the state this {Qcable} is in.
      #     The state is changed by a state machine via events that occur as the {Qcable} is processed.
      #     The possible states are:
      #     - `created`
      #     - `pending`
      #     - `failed`
      #     - `passed`
      #     - `available`
      #     - `destroyed`
      #     - `qc_in_progress`
      #     - `exhausted`.
      attribute :state, readonly: true

      # @!attribute [r] uuid
      #   @return [String] the UUID of this {Qcable}.
      attribute :uuid, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] asset
      #   @return [LabwareResource] the {Labware} resource associated with this {Qcable}.
      #   @deprecated Use the {#labware} relationship instead.
      has_one :asset

      # @!attribute [rw] labware
      #   @return [LabwareResource] the {Labware} resource associated with this {Qcable}.
      has_one :labware, relation_name: 'asset', foreign_key: :asset_id

      # @!attribute [rw] lot
      #   @return [LotResource] the {Lot} resource associated with this {Qcable}.
      has_one :lot

      ###
      # Filters
      ###

      # @!method filter_barcode
      #   Apply a filter across all {Qcable} resource , matching by barcode.
      #   @example Get all {Qcable} resources with a specific barcode.
      #     /api/v2/qcables?filter[barcode]=1234567890123
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }

      # @!method filter_uuid
      #   Apply a filter across all {Qcable} resources, matching by UUID.
      #   @example Get all {Qcable} resources with a specific UUID.
      #     /api/v2/qcables?filter[uuid]=12345678-1234-1234-1234-123456789012
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
    end
  end
end
