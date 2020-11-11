class AddServiceSpecificPrintingInfo < ActiveRecord::Migration[5.2]
  def change
    add_column :barcode_printers, :print_service, :integer, default: 0
  end
end
