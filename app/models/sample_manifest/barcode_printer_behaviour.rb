module SampleManifest::BarcodePrinterBehaviour
  ASSET_TYPE_TO_PRINTER_TYPE = {
    '1dtube' => '1D Tube',
    'plate'  => '96 Well Plate'
  }

  def applicable_barcode_printers
    printer_type = ASSET_TYPE_TO_PRINTER_TYPE[self.asset_type]
    printers     = BarcodePrinterType.find_by_name(printer_type).barcode_printers unless printer_type.nil?
    printers     = BarcodePrinter.all(:order => 'name ASC') if printers.blank?
    printers
  end
end
