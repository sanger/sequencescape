# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/barcode_printer_type_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::BarcodePrinterTypeLoader, type: :model, loader: true do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/barcode_printer_types') }

  context 'with barcode_printers_basic selected' do
    let(:selected_files) { 'barcode_printers_basic' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(BarcodePrinterType, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { a_new_record_loader.create! }.not_to change(BarcodePrinterType, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(BarcodePrinterType96Plate.last).to have_attributes(
        name: '96 Well Plate',
        printer_type_id: 1,
        label_template_name: 'sqsc_96plate_label_template_code39'
      )
    end
  end
end
