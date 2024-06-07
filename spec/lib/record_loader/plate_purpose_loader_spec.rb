# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/plate_purpose_loader'

RSpec.describe RecordLoader::PlatePurposeLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory, files: selected_files)
  end

  subject(:record_loader) { a_new_record_loader }

  let(:test_directory) { Rails.root.join('spec/data/record_loader/plate_purposes') }
  let(:created_purposes) { ['Basic Plate', 'Other Plate', 'Type with creator'] }

  context 'with no files specified' do
    let(:selected_files) { nil }

    context 'and no existing purposes' do
      before { subject.create! } # rubocop:todo RSpec/NamedSubject

      it 'creates purposes from all files' do
        expect(Purpose.where(name: created_purposes).count).to eq(3)
      end

      it 'sets the barcode printer' do
        expect(Purpose.where(name: created_purposes).last.barcode_printer_type).to eq(
          BarcodePrinterType.find_by(name: '96 Well Plate')
        )
      end
    end

    context 'with a pre-existing plate' do
      before do
        create :plate_purpose, name: created_purposes.first
        subject.create! # rubocop:todo RSpec/NamedSubject
      end

      it 'does not duplicate existing plates' do
        expect(Purpose.where(name: created_purposes).count).to eq(3)
      end
    end
  end

  context 'with a specific file specified' do
    let(:selected_files) { '002_example' }
    before { subject.create! } # rubocop:todo RSpec/NamedSubject

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

  context 'with ChromimumChip Plate purpose' do
    let(:selected_files) { '003_chromium_chip' }
    let(:purpose_name) { 'ChromiumChip Plate' }

    before { record_loader.create! }

    it 'creates a plate purpose' do
      expect(Purpose.where(name: purpose_name).count).to eq(1)
      purpose = Purpose.where(name: purpose_name).first
      expect(purpose.asset_shape).to eq(AssetShape.find_by(name: 'ChromiumChip'))
      expect(purpose.size).to eq(16)
    end
  end

  context 'with ChromimumChipX Plate purpose' do
    let(:selected_files) { '004_chromium_chip_x' }
    let(:purpose_name) { 'ChromiumChipX Plate' }

    before { record_loader.create! }

    it 'creates a plate purpose' do
      expect(Purpose.where(name: purpose_name).count).to eq(1)
      purpose = Purpose.where(name: purpose_name).first
      expect(purpose.asset_shape).to eq(AssetShape.find_by(name: 'ChromiumChipX'))
      expect(purpose.size).to eq(8)
    end
  end
end
