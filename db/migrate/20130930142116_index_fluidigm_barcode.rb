class IndexFluidigmBarcode < ActiveRecord::Migration
  def self.up
    add_index :plate_metadata, ['fluidigm_barcode'], :name=> 'index_on_fluidigm_barcode', :unique=>true
  end

  def self.down
    remove_index :name=> 'index_plate_metadata_on_fluidigm_barcode'
  end
end
