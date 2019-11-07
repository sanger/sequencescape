# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/plate_purpose_loader'

RSpec.describe RecordLoader::PlatePurposeLoader, type: :model, loader: true do
  subject do
    described_class.new(directory: test_directory, files: selected_files)
  end

  let(:test_directory) { Rails.root.join('spec', 'data', 'record_loader', 'plate_purposes') }
  let(:created_purposes) { ['Basic Plate', 'Other Plate', 'Type with creator'] }

  context 'with no files specified' do
    let(:selected_files) { nil }

    context 'and no existing purposes' do
      setup do
        subject.create!
      end

      it 'creates purposes from all files' do
        expect(Purpose.where(name: created_purposes).count).to eq(3)
      end

      it 'sets the barcode printer' do
        expect(Purpose.where(name: created_purposes).last.barcode_printer_type).to eq(BarcodePrinterType.find_by(name: '96 Well Plate'))
      end
    end

    context 'with a pre-existing plate' do
      setup do
        create :plate_purpose, name: created_purposes.first
        subject.create!
      end
      it 'does not duplicate existing plates' do
        expect(Purpose.where(name: created_purposes).count).to eq(3)
      end
    end
  end

  context 'with a specific file specified' do
    let(:selected_files) { '002_example' }
    setup do
      subject.create!
    end
    let(:the_creator) { Plate::Creator.joins(:plate_purposes).find_by(plate_purposes: { name: created_purposes.last }) }

    it 'creates purposes from the selected file files' do
      expect(Purpose.where(name: created_purposes).count).to eq(1)
      expect(Purpose.where(name: created_purposes.last).count).to eq(1)
    end

    it 'creates a plate creator' do
      expect(Plate::Creator.joins(:plate_purposes).where(plate_purposes: { name: created_purposes.last })).to exist
    end

    it 'sets creator parents' do
      expect(the_creator.parent_plate_purposes).to eq(PlatePurpose.where(name: 'Stock Plate'))
    end
  end
end
