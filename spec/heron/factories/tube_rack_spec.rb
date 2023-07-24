# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::TubeRack, type: :model, heron: true do
  let(:study) { create(:study) }

  let(:params) do
    {
      barcode: '0000000001',
      purpose_uuid: purpose_96.uuid,
      study_uuid: study.uuid,
      tubes: {
        'A01' => {
          barcode: 'FD00000001',
          content: {
            supplier_name: 'PHEC-nnnnnnn1'
          }
        },
        'A02' => {
          barcode: 'FD00000002',
          content: {
            supplier_name: 'PHEC-nnnnnnn2'
          }
        }
      }
    }
  end

  let(:invalid_tube) { {} }

  let!(:purpose_96) { create(:tube_rack_purpose, target_type: 'TubeRack', size: 96) }
  let!(:purpose_48) { create(:tube_rack_purpose, target_type: 'TubeRack', size: 48) }

  it 'is valid with all relevant attributes' do
    tube_rack = described_class.new(params)
    expect(tube_rack).to be_valid
  end

  it 'will create the correct number of tubes' do
    tube_rack = described_class.new(params)
    expect(tube_rack.recipients.count).to eq(params[:tubes].length)
  end

  it 'is not valid without barcode' do
    tube_rack = described_class.new(params.except(:barcode))
    expect(tube_rack).not_to be_valid
  end

  it 'is not valid without a purpose' do
    tube_rack = described_class.new(params.except(:purpose_uuid))
    expect(tube_rack).not_to be_valid
  end

  it 'is not valid if the purpose do not match a purpose' do
    params[:purpose_uuid] = SecureRandom.uuid
    tube_rack = described_class.new(params)
    expect(tube_rack).not_to be_valid
  end

  it 'is not valid without tubes' do
    tube_rack = described_class.new(params.except(:tubes))
    expect(tube_rack).not_to be_valid
  end

  it 'is not valid unless all of the tubes are valid' do
    params[:tubes]['A03'] = invalid_tube
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
      params[:tubes]['A03'] = invalid_tube
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
      tube_rack = described_class.new(params.merge(purpose_uuid: purpose_96.uuid))
      tube_rack.save
      expect(tube_rack.tube_rack.purpose).to eq(purpose_96)
    end

    it 'can create a 48 rack' do
      tube_rack = described_class.new(params.merge(purpose_uuid: purpose_48.uuid))
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
      expect(RackedTube.count).to eq(2)
    end

    it 'pads the coordinates before saving them' do
      tube_rack = described_class.new(params)
      tube_rack.save
      expect(tube_rack.tube_rack.racked_tubes.first.coordinate).to eq('A1')
    end

    it 'creates a tube rack status record' do
      tube_rack = described_class.new(params)
      expect { tube_rack.save }.to change(TubeRackStatus, :count).by(1)
    end

    it 'allows you to fetch a unique list of study names' do
      tube_rack = described_class.new(params)
      tube_rack.save

      expect(tube_rack.sample_study_names).to eq [study.name]
    end
  end
end
