# frozen_string_literal: true

module Heron
  module Factories
    module Concerns
      #
      # A foreign barcode is a barcode that has been externally set, that is added as
      # another extra barcode for the labware referred.
      # This module adds validation and processing methods for this barcodes
      module ForeignBarcodes
        def self.included(klass)
          klass.instance_eval do
            attr_accessor :barcode

            validates_presence_of :barcode
            validate :check_barcode_format, :check_foreign_barcode_unique
          end
        end

        def barcode_format
          Barcode.matching_barcode_format(barcode)
        end

        def check_barcode_format
          return if barcode_format.present?

          errors.add(:base, "The barcode '#{barcode}' is not a recognised format.")
        end

        def check_foreign_barcode_unique
          return unless Barcode.exists_for_format?(barcode_format, barcode)

          errors.add(:base, "The barcode '#{barcode}' is already in use.")
        end
      end
    end
  end
end
