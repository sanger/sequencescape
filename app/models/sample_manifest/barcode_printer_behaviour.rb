#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
module SampleManifest::BarcodePrinterBehaviour
  ASSET_TYPE_TO_PRINTER_TYPE = {
    '1dtube' => '1D Tube',
    'plate'  => '96 Well Plate'
  }

  def disabled_printer_instance
    Struct.new('DisabledPrinter', :id, :name, :barcode_printer_type_id).new(-1, 'Disabled printer')
  end

  def applicable_barcode_printers
    printer_type = ASSET_TYPE_TO_PRINTER_TYPE[self.asset_type]
    printers     = BarcodePrinterType.find_by_name(printer_type).barcode_printers unless printer_type.nil?
    printers     = BarcodePrinter.all(:order => 'name ASC') if printers.blank?

    printers.to_a.push(disabled_printer_instance)
  end
end
