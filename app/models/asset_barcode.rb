class AssetBarcode < ActiveRecord::Base
  # This class only a concurrency safe counter to generate asset barcode
  def self.new_barcode
    offset = 200000
    barcode = (AssetBarcode.create!).id + offset

    while Asset.find_by_barcode(barcode.to_s)
      barcode = (AssetBarcode.create!).id + offset
    end

    (barcode).to_s
  end
end
