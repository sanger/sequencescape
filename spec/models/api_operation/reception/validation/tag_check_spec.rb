# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::TagCheck do
  subject(:check) { described_class.new(input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.new(
      payload_labware: [], new_labware: [], new_samples: samples
    )
  end

  # A sample in the receptacle at the index, with the tag fields
  def sample(index, **fields)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: "SAMPLE-#{index}",
      supplier_sample_name: "Supplier sample #{index}",
      fields: fields.stringify_keys,
      pointer: "/labware/0/receptacles/#{index}/samples/0"
    )
  end

  context 'with samples without tags' do
    let(:samples) { [sample(0), sample(1)] }

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with samples that give their tags one way' do
    let(:samples) do
      [sample(0, i7: 'ACGT', i5: 'TTGA'), sample(1, i7: 'GGCC')]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a sample that gives its tags in more than one way' do
    let(:samples) do
      [sample(0, i7: 'ACGT', tag_group: 'Group 1', tag_index: 1)]
    end

    it 'reports the sample and the ways' do
      expect(check.errors).to eq(
        [{ pointer: '/labware/0/receptacles/0/samples/0',
           detail: 'Sample SAMPLE-0 gives its tags in more than one way: ' \
                   'i7/i5 and tag group and index' }]
      )
    end
  end

  context 'with a mixed sample whose fields have problems too' do
    let(:samples) { [sample(0, i7: 'NOT AN OLIGO', chromium_tag_well: 'A1')] }

    it 'reports only that it is mixed' do
      expect(check.errors.sole[:pointer])
        .to eq('/labware/0/receptacles/0/samples/0')
    end
  end

  context 'with a sample whose scheme finds a problem' do
    let(:samples) { [sample(0, i7: 'ACGX')] }

    it 'reports it' do
      expect(check.errors.sole[:pointer])
        .to eq('/labware/0/receptacles/0/samples/0/i7')
    end
  end

  context 'with a sample in two receptacles with different tags' do
    let(:first) { sample(0, i7: 'ACGT') }
    let(:samples) do
      [first,
       first.with(fields: { 'i7' => 'TTTT' },
                  pointer: '/labware/0/receptacles/1/samples/0')]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end
end
