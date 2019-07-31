# frozen_string_literal: true

# Barcode printer loaded with labels in the correct aspect for labelling 384
# well plates. (Used where two labels are generated per plate)
#
class BarcodePrinterType384DoublePlate < BarcodePrinterType
  def self.double_label?
    true
  end
end
