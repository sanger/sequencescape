# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::Plate, type: :model, lighthouse: true, heron: true do
  let(:purpose) do
    create(:plate_purpose, target_type: 'Plate', name: 'Stock Plate', size: '96')
  end
  let(:study) do
    create(:study)
  end
  let(:barcode) { '0000000001' }
  let(:params) do
    { study: study, plate_purpose: purpose, barcode: barcode }
  end

  include BarcodeHelper

  before do
    mock_plate_barcode_service
  end

  context 'with valid params' do
    let(:plate_factory) { described_class.new(params) }

    it 'can build a valid plate factory' do
      expect(plate_factory).to be_valid
    end
  end

  context 'with invalid params' do
    it 'is not valid without barcode' do
      factory = described_class.new(study: study, plate_purpose: purpose)
      expect(factory).to be_invalid
    end

    it 'is not valid without a plate purpose' do
      factory = described_class.new(study: study, barcode: barcode)
      expect(factory).to be_invalid
    end

    it 'is not valid without a study' do
      factory = described_class.new(plate_purpose: purpose, barcode: barcode)
      expect(factory).to be_invalid
    end
  end

  describe '#save' do
    let(:plate_factory) { described_class.new(params) }

    it 'can persist a new plate' do
      expect do
        plate_factory.save
      end.to change(Plate, :count).by(1)
    end

    it 'does not create several plates in subsequent calls' do
      expect do
        plate_factory.save
        plate_factory.save
      end.to raise_error(StandardError).and(change(Plate, :count).by(1))
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
        { barcode: barcode, study: study, plate_purpose: purpose, wells_content: wells_content }
      end

      it 'persists the plate' do
        expect do
          plate_factory.save
        end.to change(Plate, :count).by(1)
      end

      it 'creates the new samples' do
        expect { plate_factory.save }.to change(Plate, :count).by(1).and(
          change(Sample, :count).by(2).and(change(Aliquot, :count).by(3))
        )
      end

      context 'when creating more than one sample in the same location' do
        let(:params) do
          { barcode: barcode, study: study, plate_purpose: purpose, wells_content: samples_same_location }
        end
        let(:samples_same_location) do
          {
            'A01': [{ phenotype: 'A phenotype', aliquot: { tag_id: 1 } },
                    { sample_uuid: sample.uuid, aliquot: { tag_id: 2 } }],
            'B01': { phenotype: 'A phenotype' },
            'C01': { sample_uuid: sample.uuid }
          }
        end

        it 'creates the right number of elements' do
          expect { plate_factory.save }.to change(Plate, :count).by(1).and(
            change(Sample, :count).by(2).and(change(Aliquot, :count).by(4))
          )
        end

        it 'creates the right aliquots' do
          plate_factory.save
          plate = plate_factory.plate
          first_well = plate.wells.located_at('A1').first

          expect(first_well.aliquots.count).to eq(2)
          expect(first_well.aliquots.last.sample).to eq(sample)
        end
      end
    end
  end
end
