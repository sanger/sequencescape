class AddFluidgmBarcodeField < ActiveRecord::Migration
  def self.up
    add_column :plate_metadata, :fluidgm_barcode, :string, :limit => 10
  end

  def self.down
    remove_column :plate_metadata, :fluidgm_barcode
  end
end
