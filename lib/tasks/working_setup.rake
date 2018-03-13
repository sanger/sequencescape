require './lib/oligo_enumerator'

namespace :working do
  desc 'Confirms that the environment is correct for the task'
  task :env_check do
    require_relative '../working_setup/standard_seeder'
    unless Rails.env.development?
      puts "CAUTION! You are running this task in the #{Rails.env} environment."
      puts 'This script is intended for the development environment only.'
      puts 'Running this task in test WILL cause failures, and could cause issues in other environments.'
      puts 'Are you sure you wish to continue? (Y for yes)'
      exit unless STDIN.gets.chomp == 'Y'
    end
  end

  desc 'Provide a user, study and projects'
  task basic: :env_check do
    seeder = WorkingSetup::StandardSeeder.new
    seeder.user
    seeder.study
    seeder.study_b
    seeder.project
    seeder.supplier
  end

  desc 'Build the expected barcode printers'
  task printers: ['working:env_check', :environment] do
    plate = BarcodePrinterType.find_by!(name: '96 Well Plate')
    tube = BarcodePrinterType.find_by!(name: '1D Tube')
    BarcodePrinter.find_or_create_by!(name: 'g312bc2', barcode_printer_type: plate)
    BarcodePrinter.find_or_create_by!(name: 'g311bc2', barcode_printer_type: plate)
    BarcodePrinter.find_or_create_by!(name: 'g316bc',  barcode_printer_type: plate)
    BarcodePrinter.find_or_create_by!(name: 'g317bc',  barcode_printer_type: plate)
    BarcodePrinter.find_or_create_by!(name: 'g314bc',  barcode_printer_type: plate)
    BarcodePrinter.find_or_create_by!(name: 'g311bc1', barcode_printer_type: tube)
  end

  desc 'Provides 30 tag plates for use'
  task generate_tag_plates: :environment do
    WorkingSetup::StandardSeeder.new.tag_plates
  end

  desc 'Provide some much needed records for quickly testing new work'
  task setup: ['working:env_check', 'working:printers', 'working:basic', :environment] do
    ActiveRecord::Base.transaction do
      seeder = WorkingSetup::StandardSeeder.new([
        ['Stock Plate', 1],
        # ['LB Cherrypick', 4],
        ['ILC Stock', 4]
      ])
      seeder.seed
      seeder.tag_plates
    end
  end
end
