# frozen_string_literal: true
module SampleManifest::BarcodePrinterBehaviour # rubocop:todo Style/Documentation
  ASSET_TYPE_TO_PRINTER_TYPE = {
    '1dtube' => [BarcodePrinterType1DTube],
    'plate' => [BarcodePrinterType96Plate, BarcodePrinterType384DoublePlate]
  }.freeze

  def applicable_barcode_printers
    printer_type_classes = ASSET_TYPE_TO_PRINTER_TYPE[asset_type]
    printers = []
    if printer_type_classes.nil?
      printers += BarcodePrinter.alphabetical
    else
      printer_type_classes.each do |printer_type_class|
        BarcodePrinterType
          .where(type: printer_type_class)
          .find_each { |printer_type| printers += printer_type.barcode_printers unless printer_type.nil? }
      end
    end
    printers
  end
end
