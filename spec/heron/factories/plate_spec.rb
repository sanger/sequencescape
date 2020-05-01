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
    shared_examples_for 'an invalid parameter' do
      let(:factory) { described_class.new(params) }
      it 'is not valid' do
        expect(factory).to be_invalid
      end

      it 'has an error' do
        factory.validate
        expect(factory.errors.full_messages).to eq(error_messages)
      end
    end

    context 'without a barcode' do
      let(:params) { { plate_purpose: purpose } }
      let(:error_messages) do
        ["Barcode can't be blank",
         "The barcode '' is not a recognised format."]
      end

      it_behaves_like 'an invalid parameter'
    end

    context 'without a plate purpose' do
      let(:params) { { barcode: barcode } }
      let(:error_messages) { ['You have to define either plate_purpose_uuid or plate_purpose'] }

      it_behaves_like 'an invalid parameter'
    end

    context 'with a plate purpose uuid set to nil' do
      let(:params) { { plate_purpose_uuid: nil, barcode: barcode } }
      let(:error_messages) { ['Plate purpose for uuid () do not exist'] }

      it_behaves_like 'an invalid parameter'
    end

    context 'with a plate purpose set to nil' do
      let(:params) { { plate_purpose: nil, barcode: barcode } }
      let(:error_messages) { ["Plate purpose can't be blank"] }

      it_behaves_like 'an invalid parameter'
    end

    context 'with a plate purpose uuid that do not exist' do
      let(:uuid) { SecureRandom.uuid }
      let(:params) { { plate_purpose_uuid: uuid, barcode: barcode } }
      let(:error_messages) { ["Plate purpose for uuid (#{uuid}) do not exist"] }

      it_behaves_like 'an invalid parameter'
    end

    context 'with both plate purpose uuid and plate purpose' do
      let(:params) { { plate_purpose_uuid: purpose.uuid, plate_purpose: purpose, barcode: barcode } }
      let(:error_messages) { ['You cannot define plate_purpose_uuid and plate_purpose at same time'] }

      it_behaves_like 'an invalid parameter'
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
