# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of a barcode printer.
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class BarcodePrinterResource < BaseResource
      immutable

      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [r]
      # @return [String] The name of the barcode printer.
      attribute :name

      # @!attribute [r]
      # @return [String] The UUID of the barcode printer.
      attribute :uuid, readonly: true

      # @!attribute [r]
      # @return [String] The service this printer can be instructed to print from.
      attribute :print_service, readonly: true

      # @!attribute [r]
      # @return [String] The name of the barcode type for this printer.
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
