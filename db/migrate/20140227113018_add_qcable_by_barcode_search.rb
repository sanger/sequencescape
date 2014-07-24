class AddQcableByBarcodeSearch < ActiveRecord::Migration
 def self.up
    Search::FindQcableByBarcode.create!(:name=>'Find qcable by barcode')
  end

  def self.down
    Search.find_by_name('Find qcable by barcode').destroy!
  end
end
