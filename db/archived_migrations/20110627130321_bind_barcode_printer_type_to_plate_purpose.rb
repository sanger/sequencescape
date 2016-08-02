#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class BindBarcodePrinterTypeToPlatePurpose < ActiveRecord::Migration
  def self.up
    # We know that the 96 well printer type has ID 2
    add_column :plate_purposes, :barcode_printer_type_id, :integer, :default => 2
  end

  def self.down
    remove_column :plate_purposes, :barcode_printer_type_id
  end
end
