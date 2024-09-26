# frozen_string_literal: true

ActiveRecord::Base.transaction do
  barcode_printer_type = BarcodePrinterType.find_by(name: '1D Tube') or raise 'Cannot find 1D printer'

  {
    'Standard MX' => %w[Tube::StandardMx MultiplexedLibraryTube],
    'Standard library' => %w[Tube::Purpose LibraryTube],
    'Standard sample' => %w[Tube::Purpose SampleTube],
    'Stock MX' => %w[Tube::StockMx StockMultiplexedLibraryTube],
    'Stock library' => %w[Tube::Purpose StockLibraryTube],
    'Legacy MX tube' => %w[IlluminaHtp::MxTubePurpose MultiplexedLibraryTube]
  }.each do |name, (type, asset_type)|
    type.constantize.create!(name: name, barcode_printer_type: barcode_printer_type, target_type: asset_type)
  end
end
