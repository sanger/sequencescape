class IndexFluidgmBarcode < ActiveRecord::Migration
  def self.up
    add_index :plate_metadata, ['fluidgm_barcode'], :name=> 'index_on_fluidgm_barcode', :unique=>true
  end

  def self.down
    remove_index :name=> 'index_plate_metadata_on_fluidgm_barcode'
  end
end
