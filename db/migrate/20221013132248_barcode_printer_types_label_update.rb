# frozen_string_literal: true

# Update the label template name
class BarcodePrinterTypesLabelUpdate < ActiveRecord::Migration[6.0]
  def up
    barcode_printer = BarcodePrinterType.find_by(name: '1D Tube')
    barcode_printer.update(label_template_name: 'tube_label_template_1d')
  end

  def down
    barcode_printer = BarcodePrinterType.find_by(name: '1D Tube')
    barcode_printer.update(label_template_name: 'sqsc_1dtube_label_template')
  end
end
