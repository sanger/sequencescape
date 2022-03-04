# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Heron::Factories::Sample, type: :model, lighthouse: true, heron: true do
  let(:study) { create :study }

  describe '#valid?' do
    context 'when receiving a study instance' do
      let(:params) { { study: study } }

      it 'is valid' do
        factory = described_class.new(params)
        expect(factory).to be_valid
      end
    end

    context 'when receiving a column that does not exist in sample or sample metadata' do
      let(:params) { { study: study, asdf: 'wrong' } }

      it 'is not valid' do
        factory = described_class.new(params)
        expect(factory).to be_invalid
      end

      it 'stores the error message' do
        factory = described_class.new(params)
        factory.validate
        expect(factory.errors.full_messages).to eq(['Asdf Unexisting field for sample or sample_metadata'])
      end
    end

    context 'when receiving other fields and sample_uuid' do
      let(:sample) { create(:sample) }
      let(:params) { { study: study, phenotype: 'A phenotype', sample_uuid: sample.uuid } }

      it 'is not valid' do
        factory = described_class.new(params)
        expect(factory).to be_invalid
      end

      it 'stores the error message' do
        factory = described_class.new(params)
        factory.validate
        expect(factory.errors.full_messages).to eq(
          ['Phenotype No other params can be added when sample uuid specified']
        )
      end
    end

    context 'when receiving a study uuid' do
      context 'when the study uuid exists' do
        let(:params) { { study_uuid: study.uuid } }

        it 'is valid' do
          factory = described_class.new(params)
          expect(factory).to be_valid
        end
      end

      context 'when it does not exist' do
        let(:params) { { study_uuid: SecureRandom.uuid } }

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

  describe '#create_aliquot_at' do
    context 'when the factory is valid' do
      let(:well) { create :well }
      let(:tag_id) { 1 }
      let(:factory) { described_class.new(study: study, aliquot: { tag_id: tag_id }) }

      it 'can create an aliquot of the sample in the well' do
        expect { factory.create_aliquot_at(well) }.to change(::Aliquot, :count)
          .by(1)
          .and(change(::Sample, :count).by(1))
      end

      it 'creates aliquots using the arguments provided' do
        aliquot = factory.create_aliquot_at(well)
        expect(aliquot.class).to eq(::Aliquot)
        expect(aliquot.tag_id).to eq(tag_id)
      end

      it 'registers a stock resource message' do
        expect { factory.create_aliquot_at(well) }.to change(
          ::Messenger.where(root: 'stock_resource', template: 'WellStockResourceIO', target: well),
          :count
        ).by(1)
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

      it 'returns the same sample instance in any subsequent call' do
        factory = described_class.new(study: study)
        sample = factory.create
        sample2 = factory.create
        expect(sample).to eq(sample2)
      end

      it 'creates one sample' do
        factory = described_class.new(study: study)
        expect { factory.create }.to change(Sample, :count).by(1)
      end

      it 'creates one uuid for the sample' do
        factory = described_class.new(study: study)
        sample = factory.create
        expect(Uuid.where(resource: sample).count).to eq(1)
      end

      context 'when providing sample_uuid' do
        let(:sample) { create(:sample) }

        it 'wont create a new sample' do
          factory = described_class.new(study: study, sample_uuid: sample.uuid)
          expect { factory.create }.not_to change(Sample, :count)
        end

        it 'will return the sample with uuid specified' do
          factory = described_class.new(study: study, sample_uuid: sample.uuid)
          expect(factory.create).to eq(sample)
        end

        it 'will be invalid if providing any other extra attributes' do
          factory = described_class.new(study: study, sample_uuid: sample.uuid, sample_id: '1234')
          expect(factory).to be_invalid
        end

        it 'will be valid if providing any other attributes not sample related' do
          factory = described_class.new(study: study, sample_uuid: sample.uuid, aliquot: { tag_id: 1 })
          expect(factory).to be_valid
        end
      end

      context 'when providing a sanger_sample_id' do
        let(:sample_id) { 'test' }
        let(:factory) { described_class.new(study: study, sanger_sample_id: sample_id) }

        it 'sets the id provided as sanger_sample_id' do
          expect(factory.create.sanger_sample_id).to eq(sample_id)
        end
      end

      context 'when providing a name' do
        let(:sample_id) { 'test' }
        let(:factory) { described_class.new(study: study, name: sample_id) }

        it 'sets the id provided as name' do
          expect(factory.create.name).to eq(sample_id)
        end
      end

      context 'when providing both sanger_sample_id and name' do
        let(:sample_id) { 'test' }
        let(:name) { 'testingname' }
        let(:factory) { described_class.new(study: study, name: name, sanger_sample_id: sample_id) }

        it 'sets the id provided as sanger_sample_id' do
          expect(factory.create.sanger_sample_id).to eq(sample_id)
        end

        it 'sets the id provided as name' do
          expect(factory.create.name).to eq(name)
        end

        it 'does not generate a new sanger_sample_id' do
          expect { factory.create }.not_to change(SangerSampleId, :count)
        end
      end

      context 'when not providing a sanger_sample_id' do
        let(:factory) { described_class.new(study: study) }

        it 'generates a new sanger_sample_id' do
          sample = nil
          expect { sample = factory.create }.to change(SangerSampleId, :count).by(1)
          expect(sample.sanger_sample_id).not_to be_nil
        end

        it 'sets the new sanger_sample_id provided as sample name' do
          sample = factory.create
          expect(sample.name).to eq(sample.sanger_sample_id)
        end
      end

      context 'when providing replace_uuid' do
        let(:replaced_uuid) { SecureRandom.uuid }

        context 'when the uuid does not exist already' do
          it 'creates a new sample using that uuid' do
            factory = described_class.new(study: study, uuid: replaced_uuid)
            sample = factory.create
            expect(sample.uuid).to eq(replaced_uuid)
          end

          it 'only creates one uuid' do
            factory = described_class.new(study: study, uuid: replaced_uuid)
            sample = factory.create
            expect(Uuid.where(resource: sample).count).to eq(1)
          end
        end

        context 'when the uuid already exist' do
          let(:sample) { create :sample }

          it 'will be invalid if providing any other extra attributes' do
            factory = described_class.new(study: study, uuid: sample.uuid)
            expect { factory.create }.to raise_error(StandardError)
          end
        end
      end

      context 'when providing other arguments' do
        it 'updates other sample attributes' do
          factory = described_class.new(study: study, control: true)
          sample = factory.create
          expect(sample.control).to be(true)
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
