# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::PlateFromRack, :heron, type: :model do
  let(:purpose) { create(:plate_purpose, target_type: 'Plate', name: 'Stock Plate', size: '96') }
  let(:rack) { create(:tube_rack) }
  let(:plate_factory) { described_class.new(tube_rack: rack, plate_purpose: purpose) }
  let(:tubes) { create_list(:sample_tube, 2) }

  include BarcodeHelper

  before { mock_plate_barcode_service }

  it 'can build a valid plate factory from a rack' do
    expect(plate_factory).to be_valid
  end

  describe '#save' do
    before do
      rack.racked_tubes << create(:racked_tube, tube: tubes[0], coordinate: 'A1')
      rack.racked_tubes << create(:racked_tube, tube: tubes[1], coordinate: 'B1')
    end

    it 'creates a plate from the rack' do
      expect { plate_factory.save }.to change(Plate, :count).by(1)
    end

    it 'creates the wells for the plate' do
      expect { plate_factory.save }.to change(Well, :count).by(96)
    end

    it 'sets the aliquots from the samples in the plate' do
      expect { plate_factory.save }.to change(Aliquot, :count).by(2)
    end

    it 'sets the samples in the plate' do
      plate_factory.save
      plate = plate_factory.plate
      expect(plate.wells.map(&:samples).flatten.uniq.compact).to eq(tubes.map(&:samples).flatten.uniq.compact)
    end
  end
end
