# frozen_string_literal: true

require 'sanger_barcode_format'
# A collection of supported formats
module Barcode::FormatHandlers
  #
  # The original Sequencescape barcode format. results in:
  # Human readable form: DN12345U
  # Ean13 compatible machine readable form: 1220012345855
  # This class mostly wraps the SBCF Gem
  #
  # @author [jg16]
  #
  class SangerEan13
    attr_reader :barcode_object
    def initialize(barcode)
      @barcode_object = SBCF::SangerBarcode.from_human(barcode)
    end

    delegate :human_barcode, to: :barcode_object
    delegate_missing_to :barcode_object

    # The gem was yielding integers for backward compatible reasons.
    # We'll convert for the time being, but should probably fix that.
    def machine_barcode
      barcode_object.machine_barcode.to_s
    end

    alias ean13_barcode machine_barcode
    alias code128_barcode machine_barcode
    alias serialize_barcode human_barcode

    def ean13_barcode?
      true
    end

    def code128_barcode?
      true
    end

    def barcode_prefix
      prefix.human
    end

    def summary
      {
        number: number.to_s,
        prefix: barcode_prefix,
        ean13: ean13_barcode
      }
    end
  end
end
