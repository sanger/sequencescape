# frozen_string_literal: true
# A barcode prefix is a two character prefix applied to the front of Sanger format
# barcodes. Prefixes are set based on the {Purpose} with the most common being:
#   - DN for most plates
#   - NT for most tubes
# Historically these were converted to numbers when generating ean13 for printing
# barcodes, but now we use Code39 to encode the human-readable format directly.
# @see https://github.com/sanger/sanger_barcode_format
class BarcodePrefix < ApplicationRecord
  has_many :assets
end
