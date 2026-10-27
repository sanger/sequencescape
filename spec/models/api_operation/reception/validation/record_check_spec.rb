# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::RecordCheck do
  subject(:check) { described_class.new(input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.new(
      payload_labware: [], new_labware: [], new_samples: samples
    )
  end

  # A sample in the receptacle at the index, with valid values unless given
  def sample(index, fields: {}, **values)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: "SAMPLE-#{index}",
      supplier_sample_name: "Supplier sample #{index}",
      fields: fields.stringify_keys,
      pointer: "/labware/0/receptacles/#{index}/samples/0", **values
    )
  end

  def pointer(index, field)
    "/labware/0/receptacles/#{index}/samples/0/#{field}"
  end

  context 'with valid values' do
    let(:samples) do
      [sample(0, sanger_sample_id: 'Sample_1-a',
                 fields: { donor_id: 'Dönor 1', bioscan_supplier_name: 'B1' })]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  ['SAMPLE 1', 'S1/2', 'Échantillon'].each do |name|
    context "with #{name} as the Sanger sample ID" do
      let(:samples) { [sample(0, sanger_sample_id: name)] }

      it 'reports it, as it becomes the sample name' do
        expect(check.errors).to eq(
          [{ pointer: pointer(0, 'sanger_sample_id'),
             detail: "Sanger sample ID #{name} can only contain letters, " \
                     'numbers, _ or -, as it becomes the sample name' }]
        )
      end
    end
  end

  context 'with a supplier sample name that is not ASCII' do
    let(:samples) { [sample(0, supplier_sample_name: 'Échantillon été')] }

    it 'reports it, with the characters' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'supplier_sample_name'),
           detail: 'supplier_sample_name only allows ASCII characters, ' \
                   'not É and é' }]
      )
    end
  end

  context 'with a Bioscan supplier name that is not ASCII' do
    let(:samples) do
      [sample(0, fields: { bioscan_supplier_name: 'Naïve' })]
    end

    it 'reports it' do
      expect(check.errors.sole[:pointer])
        .to eq(pointer(0, 'bioscan_supplier_name'))
    end
  end

  context 'with an emoji in the donor ID' do
    let(:samples) { [sample(0, fields: { donor_id: 'Donor 🙂' })] }

    it 'reports it, with the characters' do
      expect(check.errors).to eq(
        [{ pointer: pointer(0, 'donor_id'),
           detail: 'donor_id contains supplementary characters (eg. emoji), ' \
                   'remove or replace them: 🙂' }]
      )
    end
  end

  context 'with a sample in more than one receptacle' do
    let(:first) { sample(0, sanger_sample_id: 'SAMPLE 1') }
    let(:samples) do
      [first, first.with(pointer: '/labware/0/receptacles/1/samples/0')]
    end

    it 'reports it once' do
      expect(check.errors.size).to eq(1)
    end
  end

  context 'with several problems in one sample' do
    let(:samples) do
      [sample(0, sanger_sample_id: 'SAMPLE 1', supplier_sample_name: 'é',
                 fields: { donor_id: '🙂' })]
    end

    it 'reports each' do
      expect(check.errors.pluck(:pointer)).to eq(
        [pointer(0, 'sanger_sample_id'), pointer(0, 'supplier_sample_name'),
         pointer(0, 'donor_id')]
      )
    end
  end
end
