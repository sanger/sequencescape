# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
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
            validate :check_barcode
          end
        end

        def barcode_format
          Barcode.matching_barcode_format(barcode)
        end

        def check_barcode
          if barcode_format.nil?
            error_message = "The barcode '#{barcode}' is not a recognised format."
            errors.add(:base, error_message)
            return false
          end
          true
        end
      end
    end
  end
end
