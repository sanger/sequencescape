# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::SampleCheck do
  subject(:check) { described_class.new(input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.new(
      payload_labware: [], new_labware: [], new_samples: samples
    )
  end

  let(:study) { create(:study) }

  # A sample in the receptacle at the index, with valid values unless given
  def sample(index, **values)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: study.uuid,
      sanger_sample_id: "SAMPLE-#{index}",
      supplier_sample_name: "Supplier sample #{index}", fields: {},
      pointer: "/labware/0/receptacles/#{index}/samples/0", **values
    )
  end

  # The entry of the sample in the receptacle at the index
  def replicate(sample, index, **values)
    sample.with(pointer: "/labware/0/receptacles/#{index}/samples/0", **values)
  end

  context 'with valid samples' do
    let(:samples) { [sample(0), sample(1)] }

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'without samples' do
    let(:samples) { [] }

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  describe 'studies' do
    let(:unknown) { SecureRandom.uuid }
    let(:other_unknown) { SecureRandom.uuid }

    context 'with a study used by several samples that does not exist' do
      let(:samples) do
        [sample(0), sample(1, study_uuid: unknown),
         sample(2, study_uuid: unknown)]
      end

      it 'reports it once, at its first sample, with how many use it' do
        expect(check.errors).to eq(
          [{ pointer: '/labware/0/receptacles/1/samples/0/study_uuid',
             detail: "No study with UUID #{unknown} (used by 2 samples)" }]
        )
      end
    end

    context 'with two studies that do not exist' do
      let(:samples) do
        [sample(0, study_uuid: unknown), sample(1, study_uuid: other_unknown)]
      end

      it 'reports each' do
        expect(check.errors.pluck(:detail)).to eq(
          ["No study with UUID #{unknown} (used by 1 sample)",
           "No study with UUID #{other_unknown} (used by 1 sample)"]
        )
      end
    end
  end

  describe 'a sample in more than one receptacle' do
    let(:first) { sample(0) }

    context 'when its entries agree' do
      let(:samples) { [first, replicate(first, 1)] }

      it 'finds no errors' do
        expect(check.errors).to be_empty
      end
    end

    context 'when an entry differs' do
      let(:samples) do
        [first, replicate(first, 1, sanger_sample_id: 'OTHER-1',
                                    study_uuid: create(:study).uuid)]
      end

      it 'reports the entry and how it differs' do
        expect(check.errors).to eq(
          [{ pointer: '/labware/0/receptacles/1/samples/0',
             detail: "Sample #{first.uuid} has a different sanger_sample_id " \
                     'and study_uuid from /labware/0/receptacles/0/samples/0' }]
        )
      end
    end
  end

  context 'with two samples with one Sanger sample ID' do
    let(:samples) do
      [sample(0, sanger_sample_id: 'SAMPLE-1'),
       sample(1, sanger_sample_id: 'sample-1')]
    end

    it 'reports the second, ignoring case' do
      expect(check.errors).to eq(
        [{ pointer: '/labware/0/receptacles/1/samples/0/sanger_sample_id',
           detail: 'Sanger sample ID sample-1 is also used by another ' \
                   'sample, at /labware/0/receptacles/0/samples/0' }]
      )
    end
  end

  describe 'UUIDs Sequencescape already uses' do
    context "with a sample's UUID" do
      let(:existing) { create(:sample) }
      let(:samples) { [sample(0, uuid: existing.uuid)] }

      it 'reports it' do
        expect(check.errors).to eq(
          [{ pointer: '/labware/0/receptacles/0/samples/0/uuid',
             detail: "UUID #{existing.uuid} is already used in " \
                     'Sequencescape' }]
        )
      end
    end

    context "with another record's UUID" do
      let(:samples) { [sample(0, uuid: study.uuid)] }

      it 'reports it' do
        expect(check.errors.sole[:pointer])
          .to eq('/labware/0/receptacles/0/samples/0/uuid')
      end
    end

    context 'with a sample in more than one receptacle' do
      let(:first) { sample(0, uuid: create(:sample).uuid) }
      let(:samples) { [first, replicate(first, 1)] }

      it 'reports it once' do
        expect(check.errors.size).to eq(1)
      end
    end
  end

  describe 'Sanger sample IDs Sequencescape already uses' do
    context "with a sample's Sanger sample ID" do
      let(:existing) { create(:sample_with_sanger_sample_id) }
      let(:samples) do
        [sample(0, sanger_sample_id: existing.sanger_sample_id)]
      end

      it 'reports it' do
        expect(check.errors).to eq(
          [{ pointer: '/labware/0/receptacles/0/samples/0/sanger_sample_id',
             detail: "Sanger sample ID #{existing.sanger_sample_id} is " \
                     'already used by a sample in Sequencescape' }]
        )
      end
    end

    context "with a sample's name, in another case" do
      let(:samples) { [sample(0, sanger_sample_id: 'EXISTING_SAMPLE')] }

      before { create(:sample, name: 'Existing_sample') }

      it 'reports it' do
        expect(check.errors.sole[:pointer])
          .to eq('/labware/0/receptacles/0/samples/0/sanger_sample_id')
      end
    end
  end
end
