# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::Sample, type: :model, lighthouse: true, heron: true do
  let(:study) { create :study }

  describe '#valid?' do
    context 'when receiving a study instance' do
      let(:params) { { "study": study } }

      it 'is valid' do
        factory = described_class.new(params)
        expect(factory).to be_valid
      end
    end

    context 'when receiving a study uuid' do
      context 'when the study uuid exists' do
        let(:params) { { "study_uuid": study.uuid } }

        it 'is valid' do
          factory = described_class.new(params)
          expect(factory).to be_valid
        end
      end

      context 'when it does not exist' do
        let(:params) { { "study_uuid": SecureRandom.uuid } }

        it 'is valid' do
          factory = described_class.new(params)
          expect(factory).to be_invalid
        end
      end
    end

    context 'when not receiving any study' do
      let(:params) { {} }

      it 'is invalid' do
        factory = described_class.new(params)
        expect(factory).to be_invalid
      end
    end
  end

  describe '#create' do
    context 'when the factory is invalid' do
      it 'returns nil' do
        factory = described_class.new({})
        expect(factory.create).to be_nil
      end
    end

    context 'when the factory is valid' do
      it 'returns a sample instance' do
        factory = described_class.new(study: study)
        expect(factory.create.class).to eq(::Sample)
      end

      context 'when providing a sanger_sample_id' do
        let(:sample_id) { 'test' }
        let(:factory) do
          described_class.new(study: study, sanger_sample_id: sample_id)
        end

        it 'does not generate a new sanger_sample_id' do
          expect  do
            factory.create
          end.not_to change(SangerSampleId, :count)
        end

        it 'sets the id provided as sample name' do
          expect(factory.create.name).to eq(sample_id)
        end

        it 'sets the id provided as sanger_sample_id' do
          expect(factory.create.sanger_sample_id).to eq(sample_id)
        end
      end

      context 'when not providing a sanger_sample_id' do
        let(:factory) do
          described_class.new(study: study)
        end

        it 'generates a new sanger_sample_id' do
          sample = nil
          expect do
            sample = factory.create
          end.to change(SangerSampleId, :count).by(1)
          expect(sample.sanger_sample_id).not_to be_nil
        end

        it 'sets the new sanger_sample_id provided as sample name' do
          sample = factory.create
          expect(sample.name).to eq(sample.sanger_sample_id)
        end
      end

      context 'when providing other arguments' do
        it 'updates other sample attributes' do
          factory = described_class.new(study: study, control: true)
          sample = factory.create
          expect(sample.control).to eq(true)
        end

        it 'updates other sample_metadata attributes' do
          factory = described_class.new(study: study, phenotype: 'A phenotype')
          sample = factory.create
          expect(sample.sample_metadata.phenotype).to eq('A phenotype')
        end
      end
    end
  end
end
