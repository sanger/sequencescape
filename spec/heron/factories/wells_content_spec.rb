# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::WellsContent, type: :model, lighthouse: true, heron: true do
  let(:factory) { described_class.new(params) }
  let(:study) { create :study }

  include BarcodeHelper

  before do
    mock_plate_barcode_service
  end

  context 'with valid params' do
    let(:params) { {} }

    it 'can build a valid wells content factory' do
      expect(factory).to be_valid
    end
  end

  context 'with invalid params' do
    it 'is not valid if keys are not valid coordinates' do
      factory = described_class.new('test1': [])
      expect(factory).to be_invalid
    end

    it 'is not valid if the samples factories are not valid either' do
      factory = described_class.new('A1': { 'asdf': 'wrong' })
      expect(factory).to be_invalid
    end
  end

  describe '#add_aliquots_into_plate' do
    let(:purpose) do
      create(:plate_purpose, target_type: 'Plate', name: 'Stock Plate', size: '96')
    end
    let(:plate) { purpose.create! }

    context 'when receiving empty config' do
      let(:params) { {} }

      it 'does nothing' do
        expect do
          factory.add_aliquots_into_plate(plate)
        end.not_to change(Aliquot, :count)
      end
    end

    context 'when providing samples information' do
      let!(:sample) { create(:sample) }
      let(:params) do
        {
          'A01': { phenotype: 'A phenotype', study_uuid: study.uuid },
          'B01': { phenotype: 'A phenotype', study_uuid: study.uuid },
          'C01': { sample_uuid: sample.uuid }
        }
      end

      it 'is valid' do
        expect(factory).to be_valid
      end

      it 'creates the new aliquots' do
        expect do
          factory.add_aliquots_into_plate(plate)
        end.to change(Sample, :count).by(2).and(change(Aliquot, :count).by(3))
      end

      context 'when creating more than one aliquot in the same location' do
        let(:params) do
          {
            'A01': [{ phenotype: 'A phenotype', aliquot: { tag_id: 1 }, study_uuid: study.uuid },
                    { sample_uuid: sample.uuid, aliquot: { tag_id: 2 } }],
            'B01': { phenotype: 'A phenotype', study_uuid: study.uuid },
            'C01': { sample_uuid: sample.uuid }
          }
        end

        it 'is valid' do
          expect(factory).to be_valid
        end

        it 'creates the right number of elements' do
          expect do
            factory.add_aliquots_into_plate(plate)
          end.to change(Sample, :count).by(2).and(change(Aliquot, :count).by(4))
        end

        it 'creates the right aliquots' do
          factory.add_aliquots_into_plate(plate)
          first_well = plate.wells.located_at('A1').first

          expect(first_well.aliquots.count).to eq(2)
          expect(first_well.aliquots.last.sample).to eq(sample)
        end
      end
    end
  end
end
