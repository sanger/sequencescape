# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/barcode_printers/` endpoint.
    #
    # Provides a JSON:API representation of {BarcodePrinter}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class BarcodePrinterResource < BaseResource
      immutable

      ###
      # Attributes
      ###

      # @!attribute [r] name
      #   @return [String] the name of the barcode printer.
      attribute :name, readonly: true

      # @!attribute [r] uuid
      #   @return [String] the UUID of the barcode printer.
      attribute :uuid, readonly: true

      # @!attribute [r] print_service
      #   @return [String] the service this printer can be instructed to print from.
      attribute :print_service, readonly: true

      # @!attribute [r] barcode_type
      #   @return [String] the name of the barcode type for this printer.
      attribute :barcode_type, readonly: true

      ###
      # Getters and Setters
      ###

      def barcode_type
        @model.barcode_printer_type.name
      end
    end
  end
end
