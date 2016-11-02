class AddLabelTemplateNameToBarcodePrinterType < ActiveRecord::Migration
  def change
    add_column :barcode_printer_types, :label_template_name, :string
  end
end
