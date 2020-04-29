# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::Plate, type: :model, lighthouse: true, heron: true do
  let(:purpose) do
    create(:plate_purpose, target_type: 'Plate', name: 'Stock Plate', size: '96')
  end
  let(:study) do
    create(:study)
  end
  let(:plate_factory) { described_class.new(params) }
  let(:params) do
    { study: study, plate_purpose: purpose }
  end

  include BarcodeHelper

  before do
    mock_plate_barcode_service
  end

  it 'can build a valid plate factory' do
    expect(plate_factory).to be_valid
  end

  describe '#create' do
    it 'can create a new plate' do
      expect do
        plate_factory.create
      end.to change(Plate, :count).by(1)
    end

    it 'returns the same instance in any subsequent call' do
      plate = plate_factory.create
      plate2 = plate_factory.create
      expect(plate).to eq(plate2)
    end

    context 'when providing samples information' do
      let!(:sample) { create(:sample) }
      let(:wells_content) do
        {
          'A01': { phenotype: 'A phenotype' },
          'B01': { phenotype: 'A phenotype' },
          'C01': { sample_uuid: sample.uuid }
        }
      end
      let(:params) do
        { study: study, plate_purpose: purpose, wells_content: wells_content }
      end

      it 'creates the plate' do
        expect do
          plate_factory.create
        end.to change(Plate, :count).by(1)
      end

      it 'creates the new samples' do
        expect { plate_factory.create }.to change(Plate, :count).by(1).and(
          change(Sample, :count).by(2).and(change(Aliquot, :count).by(3))
        )
      end

      context 'when creating more than one sample in the same location' do
        let(:params) do
          { study: study, plate_purpose: purpose, wells_content: samples_same_location }
        end
        let(:samples_same_location) do
          {
            'A01': [{ phenotype: 'A phenotype', aliquot: { tag_id: 1 } },
                    { sample_uuid: sample.uuid, aliquot: { tag_id: 2 } }],
            'B01': { phenotype: 'A phenotype' },
            'C01': { sample_uuid: sample.uuid }
          }
        end
        let(:factory) { described_class.new(params) }

        it 'creates the right number of elements' do
          expect { factory.create }.to change(Plate, :count).by(1).and(
            change(Sample, :count).by(2).and(change(Aliquot, :count).by(4))
          )
        end

        it 'creates the right aliquots' do
          plate = factory.create

          first_well = plate.wells.located_at('A1').first

          expect(first_well.aliquots.count).to eq(2)
          expect(first_well.aliquots.last.sample).to eq(sample)
        end
      end
    end
  end
end
