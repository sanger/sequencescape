# frozen_string_literal: true
# This file contains content previously in the working:setup task
# which is useful in development environments for easy debugging.
# It has been moved into seeds to streamline the process.

if Rails.env.development?
  require './lib/working_setup/standard_seeder'

  # Barcode printers (These match some of the more frequently used printers,
  # or at least the most frequently used when I first put this together)
  plate = BarcodePrinterType.find_by!(name: '96 Well Plate')
  tube = BarcodePrinterType.find_by!(name: '1D Tube')
  plate384 = BarcodePrinterType384DoublePlate.find_by!(name: '384 Well Plate Double')

  BarcodePrinter.find_or_create_by!(name: 'g312bc2', barcode_printer_type: plate)
  BarcodePrinter.find_or_create_by!(name: 'g311bc2', barcode_printer_type: plate)
  BarcodePrinter.find_or_create_by!(name: 'g316bc', barcode_printer_type: plate)
  BarcodePrinter.find_or_create_by!(name: 'g317bc', barcode_printer_type: plate)
  BarcodePrinter.find_or_create_by!(name: 'g314bc', barcode_printer_type: plate)
  BarcodePrinter.find_or_create_by!(name: 'f225bc', barcode_printer_type: plate)
  BarcodePrinter.find_or_create_by!(name: 'g311bc1', barcode_printer_type: tube)
  BarcodePrinter.find_or_create_by!(name: 'dnapbc2', barcode_printer_type: plate384)
  BarcodePrinter.find_or_create_by!(name: 'ogilviebc', barcode_printer_type: plate384)

  # Previous content of working:basic provides a few example studies
  # and the admin user
  seeder = WorkingSetup::StandardSeeder.new([['Stock Plate', 1]])
  seeder.user
  seeder.study
  seeder.study_b
  seeder.phi_x_study
  seeder.project
  seeder.supplier

  # Generates a handful of samples and robots
  seeder.seed
end
