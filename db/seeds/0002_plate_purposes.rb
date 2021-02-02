# frozen_string_literal: true

ActiveRecord::Base.transaction do
  RecordLoader::TubePurposeLoader.new(files: ['005_pulldown_legacy_purposes']).create!
  PlatePurpose.create!(
    name: 'Pre-capture stock',
    target_type: 'Plate',
    stock_plate: true,
    barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate')
  )
end
