#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddBarcodeForTecanColumn < ActiveRecord::Migration
  def self.up
    add_column :plate_purposes, :barcode_for_tecan, :string, :default=> 'ean13_barcode', :null => false
  end

  def self.down
    remove_column :plate_purposes, :barcode_for_tecan, :string
  end
end
