#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddSnpTypePlate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.create!(
        :name=>'SNP Type',
        :default_state=>'pending',
        :barcode_printer_type=>BarcodePrinterType.find_by_name('96 Well Plate'),
        :cherrypickable_target => true,
        :cherrypick_direction => 'column',
        :asset_shape => AssetShape.find_by_name('Standard')
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('SNP Type').destroy
    end
  end
end
