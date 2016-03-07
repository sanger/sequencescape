#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddFluidigmPlatePurposes < ActiveRecord::Migration
  def self.up

    ActiveRecord::Base.transaction do
      PlatePurpose.create!(
        :name=>'STA',
        :default_state=>'pending',
        :barcode_printer_type=>BarcodePrinterType.find_by_name('96 Well Plate'),
        :cherrypickable_target => true,
        :cherrypick_direction => 'column',
        :asset_shape => AssetShape.find_by_name('Standard')
      )
      PlatePurpose.create!(
        :name=>'STA2',
        :default_state=>'pending',
        :barcode_printer_type=>BarcodePrinterType.find_by_name('96 Well Plate'),
        :cherrypickable_target => true,
        :cherrypick_direction => 'column',
        :asset_shape => AssetShape.find_by_name('Standard')
      )
      PlatePurpose.create!(
        :name=>'Fluidigm 96-96',
        :default_state=>'pending',
        :cherrypickable_target => true,
        :cherrypick_direction => 'interlaced_column',
        :size => 96,
        :asset_shape => AssetShape.find_by_name('Fluidigm96')
      )
      PlatePurpose.create!(
        :name=>'Fluidigm 192-24',
        :default_state=>'pending',
        :cherrypickable_target => true,
        :cherrypick_direction => 'interlaced_column',
        :size => 192,
        :asset_shape => AssetShape.find_by_name('Fluidigm192')
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('STA').destroy
      PlatePurpose.find_by_name('STA2').destroy
      PlatePurpose.find_by_name('Fluidigm 96-96').destroy
      PlatePurpose.find_by_name('Fluidigm 192-24').destroy
    end
  end
end
