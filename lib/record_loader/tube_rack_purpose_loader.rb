# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified plate types if they are not present
  class TubeRackPurposeLoader < ApplicationRecordLoader
    DEFAULT_PRINTER_TYPE = '96 Well Plate'
    DEFAULT_TARGET_TYPE = 'TubeRack'

    config_folder 'tube_rack_purposes'

    def create_or_update!(name, options)
      options['target_type'] = DEFAULT_TARGET_TYPE
      options['barcode_printer_type'] = barcode_printer_type(options['barcode_printer_type'])
      TubeRack::Purpose.create_with(options).find_or_create_by!(name: name)
    end

    def barcode_printer_type(name)
      @printer_cache ||=
        Hash.new do |hash, uncached_type_name|
          hash[uncached_type_name] = BarcodePrinterType.find_by(name: uncached_type_name)
        end
      @printer_cache[name || DEFAULT_PRINTER_TYPE]
    end
  end
end
