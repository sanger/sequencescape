# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::TubeRack, type: :model, heron: true do
  before do
    create(:study, id: Heron::Factories::TubeRack::HERON_STUDY)
  end

  let(:params) do
    {
      "barcode": '0000000001',
      "size": '96',
      "tubes": [
        {
          "coordinate": 'A01',
          "barcode": 'FD00000001',
          "supplier_sample_id": 'PHEC-nnnnnnn1'
        },
        {
          "coordinate": 'A02',
          "barcode": 'FD00000002',
          "supplier_sample_id": 'PHEC-nnnnnnn2'
        }
      ]
    }
  end

  let(:invalid_tube) do
    {
      "coordinate": 'A03',
      "barcode": 'FD00000003'
    }
  end

  let!(:purpose_96) { create(:tube_rack_purpose, target_type: 'TubeRack', size: 96) }
  let!(:purpose_48) { create(:tube_rack_purpose, target_type: 'TubeRack', size: 48) }

  it 'is valid with all relevant attributes' do
    tube_rack = described_class.new(params)
    expect(tube_rack).to be_valid
  end

  it 'will create the correct number of tubes' do
    tube_rack = described_class.new(params)
    expect(tube_rack.tubes.count).to eq(params[:tubes].length)
  end

  it 'is not valid without barcode' do
    tube_rack = described_class.new(params.except(:barcode))
    expect(tube_rack).not_to be_valid
  end

  it 'is not valid without the size' do
    tube_rack = described_class.new(params.except(:size))
    expect(tube_rack).not_to be_valid
  end

  it 'is not valid if the size do not match a purpose' do
    params[:size] = 44
    tube_rack = described_class.new(params)
    expect(tube_rack).not_to be_valid
  end

  it 'is not valid without tubes' do
    tube_rack = described_class.new(params.except(:tubes))
    expect(tube_rack).not_to be_valid
  end

  it 'is not valid unless all of the tubes are valid' do
    params[:tubes] << invalid_tube
    tube_rack = described_class.new(params)
    expect(tube_rack).not_to be_valid
  end

  describe '#save' do
    it 'returns false if barcode is not present' do
      tube_rack = described_class.new(params.except(:barcode))
      expect(tube_rack.save).to be_falsy
    end

    it 'returns false if tubes are not present' do
      tube_rack = described_class.new(params.except(:tubes))
      expect(tube_rack.save).to be_falsy
    end

    it 'returns false if any tube is invalid' do
      params[:tubes] << invalid_tube
      tube_rack = described_class.new(params)
      expect(tube_rack.save).to be_falsy
    end

    it 'returns true if it saves correctly' do
      tube_rack = described_class.new(params)
      expect(tube_rack.save).to be_truthy
    end

    it 'creates the rack' do
      tube_rack = described_class.new(params)
      expect { tube_rack.save }.to change(TubeRack, :count).by(1)
    end

    it 'can create a 96 rack' do
      tube_rack = described_class.new(params.merge(size: 96))
      tube_rack.save
      expect(tube_rack.tube_rack.purpose).to eq(purpose_96)
    end

    it 'can create a 48 rack' do
      tube_rack = described_class.new(params.merge(size: 48))
      tube_rack.save
      expect(tube_rack.tube_rack.purpose).to eq(purpose_48)
    end

    it 'creates the tubes' do
      tube_rack = described_class.new(params)
      expect { tube_rack.save }.to change(SampleTube, :count).by(2)
    end

    it 'sets up the tube in their rack coordinate' do
      tube_rack = described_class.new(params)
      tube_rack.save
      tube_rack.racked_tubes
      expect(RackedTube.count).to eq(2)
    end

    it 'pads the coordinates before saving them' do
      tube_rack = described_class.new(params)
      tube_rack.save
      tube_rack.racked_tubes
      expect(tube_rack.racked_tubes.first.coordinate).to eq('A1')
    end
  end
end
