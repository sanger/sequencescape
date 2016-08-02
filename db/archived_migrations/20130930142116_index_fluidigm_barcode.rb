#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class IndexFluidigmBarcode < ActiveRecord::Migration
  def self.up
    add_index :plate_metadata, ['fluidigm_barcode'], :name=> 'index_on_fluidigm_barcode', :unique=>true
  end

  def self.down
    remove_index :name=> 'index_plate_metadata_on_fluidigm_barcode'
  end
end
