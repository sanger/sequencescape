#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddStripTubePurpose < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.create!(
        :name        =>'Strip Tube Purpose',
        :target_type => 'StripTube',
        :can_be_considered_a_stock_plate => false,
        :cherrypickable_target => false,
        :cherrypickable_source => false,
        :barcode_printer_type =>  BarcodePrinterType.find_by_name("96 Well Plate"),
        :cherrypick_direction => 'column',
        :size => 8,
        :asset_shape => Map::AssetShape.find_by_name('StripTubeColumn'),
        :barcode_for_tecan => 'ean13_barcode'
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name!('Strip Tube Purpose').destroy
    end
  end
end
