# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {BarcodePrinter}.
    #
    # This resource represents a barcode printer and its capabilities.
    # It allows retrieving information about registered barcode printers, including their names, types,
    #   and supported services.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/barcode_printers/` endpoint.
    #
    # @example GET request for all BarcodePrinter resources
    #   GET /api/v2/barcode_printers/
    #
    # @example GET request for a specific BarcodePrinter by ID
    #   GET /api/v2/barcode_printers/1
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or refer to the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class BarcodePrinterResource < BaseResource
      # This resource is immutable, meaning it cannot be created, updated, or deleted.
      immutable

      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [r] name
      #   @return [String] The name of the barcode printer.
      attribute :name, readonly: true

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the barcode printer.
      attribute :uuid, readonly: true

      # @!attribute [r] print_service
      #   @return [String] The service this printer can be instructed to print from. e.g "PMB"
      attribute :print_service, readonly: true

      # @!attribute [r] barcode_type
      #   @return [String] The name of the barcode type for this printer. e.g "96 Well Plate"
      attribute :barcode_type, readonly: true

      ###
      # Getters and Setters
      ###

      # Retrieves the barcode type from the associated barcode printer type.
      # @return [String] The name of the barcode type.
      # @note This attribute is read-only;
      def barcode_type
        @model.barcode_printer_type.name
      end

      ###
      # Filters
      ###

      # @!method uuid
      #   A filter to return only barcode printers with the given UUID.
      #   @example Filtering barcode printers by UUID
      #     GET /api/v2/barcode_printers?filter[uuid]=11111111-2222-3333-4444-555555666666
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(*value) }
    end
  end
end
