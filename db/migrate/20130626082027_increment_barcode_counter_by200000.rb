class IncrementBarcodeCounterBy200000 < ActiveRecord::Migration
  def self.up
    last_barcode = AssetBarcode.last.id.to_i
    execute %Q{
      INSERT INTO `asset_barcodes` (`id`) VALUES (#{last_barcode+200000});
    }
  end

  def self.down
  end
end
