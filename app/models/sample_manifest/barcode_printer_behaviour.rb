# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

module SampleManifest::BarcodePrinterBehaviour
  ASSET_TYPE_TO_PRINTER_TYPE = {
    '1dtube' => ['1D Tube'],
    'plate'  => ['96 Well Plate', '384 Well Plate Double']
  }

  def applicable_barcode_printers
    printer_types = ASSET_TYPE_TO_PRINTER_TYPE[asset_type]
    printers = []
    if printer_types.nil?
      printers += BarcodePrinter.alphabetical
    else
      printer_types.each do |printer_type|
        printers += BarcodePrinterType.find_by(name: printer_type).barcode_printers
      end
    end
    printers
  end
end
