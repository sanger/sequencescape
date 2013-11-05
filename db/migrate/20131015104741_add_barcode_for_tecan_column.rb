class AddBarcodeForTecanColumn < ActiveRecord::Migration
  def self.up
    add_column :plate_purposes, :barcode_for_tecan, :string, :default=> 'ean13_barcode', :null => false
  end

  def self.down
    remove_column :plate_purposes, :barcode_for_tecan, :string
  end
end
