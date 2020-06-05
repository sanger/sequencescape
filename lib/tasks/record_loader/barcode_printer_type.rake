# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`
namespace :record_loader do
  desc 'Automatically generate BarcodePrinterType through BarcodePrinterTypeLoader'
  task barcode_printer_type: :environment do
    RecordLoader::BarcodePrinterTypeLoader.new.create!
  end
end

# Automatically run this record loader as part of record_loader:all
# Remove this line if the task should only run when invoked explicitly
task 'record_loader:all' => 'record_loader:barcode_printer_type'
