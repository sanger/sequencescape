
class AssetBarcode < ApplicationRecord
  # This class only a concurrency safe counter to generate asset barcode
  def self.new_barcode(prefix = Tube.default_prefix)
    barcode = (AssetBarcode.create!).id

    while Barcode.find_by(barcode: SBCF::SangerBarcode.from_prefix_and_number(prefix, barcode).human_barcode)
      barcode = (AssetBarcode.create!).id
    end

    barcode.to_s
  end
end
