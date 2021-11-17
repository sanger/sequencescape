# frozen_string_literal: true

# Barcode printer loaded with labels in the correct aspect for labelling tubes
#
class BarcodePrinterType1DTube < BarcodePrinterType
  def self.first
    super || BarcodePrinterType1DTube.create!(name: '1D Tube', label_template_name: 'sqsc_1dtube_label_template')
  end
end
