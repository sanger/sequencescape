# frozen_string_literal: true

# Represents barcode printers containing labels suitable for 96 well plates.
class BarcodePrinterType96Plate < BarcodePrinterType
  def self.first
    super ||
      BarcodePrinterType96Plate.create!(
        name: '96 Well Plate',
        # Update this?
        label_template_name: 'sqsc_96plate_label_template_code39'
      )
  end
end
