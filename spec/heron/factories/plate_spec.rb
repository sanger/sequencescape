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
    { plate_purpose: purpose, barcode: barcode }
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
      factory = described_class.new(plate_purpose: purpose)
      expect(factory).to be_invalid
    end

    it 'is not valid without a plate purpose' do
      factory = described_class.new(barcode: barcode)
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
      expect(Plate.count).to eq(0)
      expect(plate_factory.save).to be_truthy
      expect(Plate.count).to eq(1)
      expect(plate_factory.save).to be_falsy
      expect(Plate.count).to eq(1)
    end

    context 'when providing samples information' do
      let!(:sample) { create(:sample) }
      let(:wells_content) do
        {
          'A01': { phenotype: 'A phenotype', study_uuid: study.uuid },
          'B01': { phenotype: 'A phenotype', study_uuid: study.uuid },
          'C01': { sample_uuid: sample.uuid }
        }
      end
      let(:params) do
        { barcode: barcode, plate_purpose: purpose, wells_content: wells_content }
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

      context 'when there is an error in the sample info' do
        let(:wells_content) do
          {
            'A01': { 'wrong': 'wrong', study_uuid: study.uuid },
            'C01': [{ 'phenotype': 'right' }, { sample_uuid: sample.uuid, 'phenotype': 'wrong' }]
          }
        end

        it 'is invalid' do
          expect(plate_factory).to be_invalid
        end

        it 'stores the error message from samples' do
          expect(plate_factory.tap(&:validate).errors.full_messages).to eq([
            'Wells content A01 Wrong Unexisting field for sample or sample_metadata',
            "Wells content C01, pos: 0 Study can't be blank",
            'Wells content C01, pos: 1 Phenotype No other params can be added when sample uuid specified'
          ])
        end
      end
    end
  end
end
