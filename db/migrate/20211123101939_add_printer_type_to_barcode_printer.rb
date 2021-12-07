# frozen_string_literal: true

# add the printer type to barcode printers as it is a required field in pmb
class AddPrinterTypeToBarcodePrinter < ActiveRecord::Migration[6.0]
  def up
    add_column :barcode_printers, :printer_type, :integer, null: true, default: 1
  end

  def down
    remove_column :barcode_printers, :printer_type
  end
end
