#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddTagTubePurpose < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
      QcableTubePurpose.create!(
        :name => 'Tag 2 Tube',
        :target_type => 'Tube',
        :qc_display => false,
        :can_be_considered_a_stock_plate => false,
        :barcode_printer_type_id => BarcodePrinterType.find_by_type('BarcodePrinterType1DTube').id,
        :cherrypickable_target => false,
        :cherrypickable_source => false,
        :size => 1,
        :barcode_for_tecan => 'ean13_barcode',
        :default_state => 'pending'
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Purpose.find_by_name('Tag 2 Tube').destroy
    end
  end
end
