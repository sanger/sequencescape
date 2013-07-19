class AssetBarcode < ActiveRecord::Base
  # This class only a concurrency safe counter to generate asset barcode
  def self.new_barcode
    barcode = (AssetBarcode.create!).id

    while Asset.find_by_barcode(barcode.to_s)
      barcode = (AssetBarcode.create!).id
    end

    (barcode).to_s
  end
end
