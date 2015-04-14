#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
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
