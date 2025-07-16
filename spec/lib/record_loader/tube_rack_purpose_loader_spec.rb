# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/tube_rack_purpose_loader'

# This file was initially generated via `rails g record_loader`
RSpec.describe RecordLoader::TubeRackPurposeLoader, :loader, type: :model do
  subject(:record_loader) { described_class.new(directory: test_directory, files: selected_files) }

  # Tests use a separate directory to avoid coupling your specs to the data
  let(:test_directory) { Rails.root.join('spec/data/record_loader/tube_rack_purposes') }

  context 'with two_tube_racks selected' do
    let(:selected_files) { 'two_tube_racks' }

    it 'creates two records' do
      expect { record_loader.create! }.to change(TubeRack::Purpose, :count).by(2)
    end

    # It is important that multiple runs of a RecordLoader do not create additional
    # copies of existing records.
    it 'is idempotent' do
      record_loader.create!
      expect { record_loader.create! }.not_to change(TubeRack::Purpose, :count)
    end

    it 'sets attributes on the created records' do
      record_loader.create!
      expect(TubeRack::Purpose.all).to include(
        have_attributes(name: 'TR Stock 96', target_type: 'TubeRack', size: 96, stock_plate: true),
        have_attributes(name: 'TR Stock 48', target_type: 'TubeRack', size: 48, stock_plate: true)
      )
    end

    it 'sets the prefix on all records' do
      expect(TubeRack::Purpose.all.map(&:prefix)).to all(have_attributes(name: 'TR'))
    end

    it 'sets barcode printer type on all records' do
      expect(TubeRack::Purpose.all.map(&:barcode_printer_type)).to all(have_attributes(name: '96 Well Plate'))
    end
  end
end
