#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddNewPurposesForQcPipeline < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      initial = Purpose.find_by_name('Tag Plate')
      purpose_order.inject(initial) do |parent,child_settings|
        child_settings.delete(:class).create(child_settings.merge(shared)).tap do |child|
          parent.child_relationships.create!(:child => child, :transfer_request_type => RequestType.find_by_name('Transfer'))
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      purpose_order.each do |child_settings|
        Purpose.find_by_name(child_settings[:name]).destroy
      end
    end
  end

  def self.purpose_order
    [
      {:class=>PlatePurpose,    :name=>'Tag PCR', :barcode_printer_type => plate, :size => 96, :asset_shape => AssetShape.find_by_name('Standard')},
      {:class=>PlatePurpose,    :name=>'Tag PCR-XP', :barcode_printer_type => plate, :size => 96, :asset_shape => AssetShape.find_by_name('Standard')},
      {:class=>Tube::StockMx,   :name=>'Tag Stock-MX', :target_type=>'StockMultiplexedLibraryTube', :barcode_printer_type => tube},
      {:class=>Tube::StandardMx,:name=>'Tag MX', :target_type=>'MultiplexedLibraryTube', :barcode_printer_type => tube},
    ]
  end

  def self.shared
    {
      :can_be_considered_a_stock_plate => false,
      :default_state => 'pending',
      :cherrypickable_target => false,
      :cherrypick_direction => 'column',
      :barcode_for_tecan => 'ean13_barcode'
    }
  end

  def self.tube
    BarcodePrinterType.find_by_name('1D Tube')
  end

  def self.plate
    BarcodePrinterType.find_by_name('96 Well PLate')
  end
end
