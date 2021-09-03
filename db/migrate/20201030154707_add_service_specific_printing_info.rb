# frozen_string_literal: true
# Add print_service field to the barcode_printers table
# To distinguise which printing service a printer users e.g PMB or SPrint
# Value is an integer defined by the enum in barcode_printer model
class AddServiceSpecificPrintingInfo < ActiveRecord::Migration[5.2]
  def change
    add_column :barcode_printers, :print_service, :integer, default: 0
  end
end
