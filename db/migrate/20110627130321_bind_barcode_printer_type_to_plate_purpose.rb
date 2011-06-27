class BindBarcodePrinterTypeToPlatePurpose < ActiveRecord::Migration
  def self.up
    # We know that the 96 well printer type has ID 2
    add_column :plate_purposes, :barcode_printer_type_id, :integer, :default => 2
  end

  def self.down
    remove_column :plate_purposes, :barcode_printer_type_id
  end
end
