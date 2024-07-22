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
      # @return [String] The name of the printer type.
      attribute :type_name

      ###
      # Getters and Setters
      ###
      def type_name
        @model.barcode_printer_type.name
      end
    end
  end
end
