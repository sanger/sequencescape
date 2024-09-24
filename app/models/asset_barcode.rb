# frozen_string_literal: true
# This class only a concurrency safe counter to generate asset barcode
# Used for {Tube tubes}
# @see PlateBarcode for the equivalent in {Plate plates}
class AssetBarcode < ApplicationRecord
  #
  # Generate a new Sanger barcode, namespaced with the given prefix
  # @param prefix [String] The two letter prefix at the beginning of the barcode (default Tube.default_prefix, NT)
  #
  # @example Generating a new barcode
  #   AssetBarcode.new_barcode #=> '12345'
  #
  # @note The returned string does NOT include the prefix.
  # @return [String] The number component of the new barcode in string format.
  def self.new_barcode(prefix = Tube.default_prefix)
    barcode = AssetBarcode.create!.id

    while Barcode.find_by(barcode: SBCF::SangerBarcode.from_prefix_and_number(prefix, barcode).human_barcode)
      barcode = AssetBarcode.create!.id
    end

    barcode.to_s
  end
end
