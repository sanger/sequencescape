class AddServiceSpecificPrintingInfo < ActiveRecord::Migration[5.2]
  def change
    add_column :barcode_printer_types, :sprint_label_template_name, :string
    add_column :barcode_printers, :print_service, :integer, default: 0
  end
end
