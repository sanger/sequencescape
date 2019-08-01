# Rails migration
class DropDefaultBarcodePurposeType < ActiveRecord::Migration
  def up
    change_column_default(:plate_purposes, :barcode_printer_type_id, nil)
  end

  def down
    change_column_default(:plate_purposes, :barcode_printer_type_id, 2)
  end
end
