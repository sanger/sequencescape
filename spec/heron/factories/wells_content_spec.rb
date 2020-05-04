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
    context 'when keys are not valid coordinates' do
      let(:params) { { 'test1': [], 'B01': [], 'test2': [] } }

      it 'is not valid' do
        factory = described_class.new(params)
        expect(factory).to be_invalid
      end

      it 'gets an error message about it for each wrong location' do
        factory = described_class.new(params)
        factory.validate
        expect(factory.errors.full_messages.uniq).to eq(
          ['Coordinate Invalid coordinate format (test1)', 'Coordinate Invalid coordinate format (test2)']
        )
      end
    end

    context 'when the samples have wrong fields' do
      let(:study) { create(:study) }
      let(:sample) { create(:sample) }
      let(:params) do
        {
          'A1': [{ 'phenotype': 'Another phenotype', 'study_uuid': study.uuid }, { 'phenotype': 'A phenotype', 'study_uuid': study.uuid }],
          'B1': [{ 'phenotype': 'Right', 'study_uuid': study.uuid }, { 'sample_uuid': sample.uuid, 'phenotype': 'wrong' }],
          'C1': { 'phenotype': 'Right', 'asdf': 'wrong' }
        }
      end

      it 'is not valid' do
        factory = described_class.new(params)
        expect(factory).to be_invalid
      end

      it 'gets an error message about it for each wrong sample' do
        expect(described_class.new(params).tap(&:validate).errors.full_messages.uniq).to eq([
          'B1, pos: 1 Phenotype No other params can be added when sample uuid specified',
          "C1 Study can't be blank",
          'C1 Asdf Unexisting field for sample or sample_metadata'
        ])
      end
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
