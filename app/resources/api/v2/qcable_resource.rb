# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/qcables/` endpoint.
    #
    # Provides a JSON:API representation of {Qcable}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class QcableResource < BaseResource
      # Constants...

      # model_name / model_hint if required

      # Associations:
      has_one :lot
      has_one :asset, polymorphic: true

      # Attributes
      attribute :uuid, readonly: true
      attribute :state, write_once: true
      attribute :labware_barcode, write_once: true

      # Filters
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.
      def labware_barcode
        {
          'ean13_barcode' => _model.ean13_barcode,
          'machine_barcode' => _model.machine_barcode,
          'human_barcode' => _model.human_barcode
        }
      end

      # Class method overrides
    end
  end
end
