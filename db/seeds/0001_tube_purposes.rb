# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

ActiveRecord::Base.transaction do
  barcode_printer_type = BarcodePrinterType.find_by(name: '1D Tube') or raise 'Cannot find 1D printer'

  {
    'Standard MX'       => ['Tube::StandardMx',            'MultiplexedLibraryTube'],
    'Standard library'  => ['Tube::Purpose',               'LibraryTube'],
    'Standard sample'   => ['Tube::Purpose',               'SampleTube'],
    'Stock MX'          => ['Tube::StockMx',               'StockMultiplexedLibraryTube'],
    'Stock library'     => ['Tube::Purpose',               'StockLibraryTube'],
    'Stock sample'      => ['Tube::Purpose',               'StockSampleTube'],
    'Legacy MX tube'    => ['IlluminaHtp::MxTubeNoQcPurpose',  'MultiplexedLibraryTube']
  }.each do |name, (type, asset_type)|
    type.constantize.create!(name: name, barcode_printer_type: barcode_printer_type, target_type: asset_type)
  end
end
