#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddRnaStockPlatePurpose < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.create!(
        :name       =>'Stock RNA Plate',
        :qc_display => true,
        :can_be_considered_a_stock_plate => true,
        :default_state => 'pending',
        :barcode_printer_type => BarcodePrinterType.find_by_name('96 Well Plate'),
        :cherrypickable_target => true,
        :cherrypickable_source => false,
        :cherrypick_direction => 'column'
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('Stock RNA Plate').destroy
    end
  end
end
