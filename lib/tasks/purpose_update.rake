namespace :purpose do
  desc 'Automatically generate absent purposes'
  task update: :environment do
    PlatePurpose.create_with(
      target_type: 'Plate',
      stock_plate: true,
      barcode_printer_type: BarcodePrinterType.find_by(name: '96 Well Plate')
    ).find_or_create_by!(name: 'Pre-capture stock')
  end
end
