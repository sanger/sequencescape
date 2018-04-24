# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

module SampleManifest::BarcodePrinterBehaviour
  ASSET_TYPE_TO_PRINTER_TYPE = {
    '1dtube' => [BarcodePrinterType1DTube],
    'plate'  => [BarcodePrinterType96Plate, BarcodePrinterType384DoublePlate]
  }

  def applicable_barcode_printers
    printer_type_classes = ASSET_TYPE_TO_PRINTER_TYPE[asset_type]
    printers = []
    if printer_type_classes.nil?
      printers += BarcodePrinter.alphabetical
    else
      printer_type_classes.each do |printer_type_class|
        BarcodePrinterType.where(type: printer_type_class).find_each do |printer_type|
          printers += printer_type.barcode_printers unless printer_type.nil?
        end
      end
    end
    printers
  end
end
