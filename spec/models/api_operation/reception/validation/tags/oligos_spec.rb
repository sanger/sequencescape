# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::Tags::Oligos do
  subject(:scheme) { described_class.new(samples, input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.new(
      payload_labware: [], new_labware: [], new_samples: samples
    )
  end

  let(:samples) { [sample(fields)] }

  def sample(fields)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: 'SAMPLE-0', supplier_sample_name: 'Supplier sample',
      fields: fields, pointer: '/labware/0/receptacles/0/samples/0'
    )
  end

  context 'with i7 and i5 of A, C, G, T and N' do
    let(:fields) { { 'i7' => 'ACGTN', 'i5' => 'acgtn' } }

    it 'finds no errors' do
      expect(scheme.errors).to be_empty
    end
  end

  context 'with only i5' do
    let(:fields) { { 'i5' => 'ACGT' } }

    it 'finds no errors' do
      expect(scheme.errors).to be_empty
    end
  end

  context 'with other letters' do
    let(:fields) { { 'i7' => 'ACGU' } }

    it 'reports the field' do
      expect(scheme.errors).to eq(
        [{ pointer: '/labware/0/receptacles/0/samples/0/i7',
           detail: 'i7 must be a combination of A, C, G, T or N' }]
      )
    end
  end

  context 'with spaces' do
    let(:fields) { { 'i5' => 'ACG T' } }

    it 'reports the field' do
      expect(scheme.errors.sole[:pointer])
        .to eq('/labware/0/receptacles/0/samples/0/i5')
    end
  end

  context 'with the longest oligo accepted' do
    let(:fields) { { 'i7' => 'A' * described_class::MAX_LENGTH } }

    it 'finds no errors' do
      expect(scheme.errors).to be_empty
    end
  end

  context 'with a longer oligo' do
    let(:fields) { { 'i7' => 'A' * (described_class::MAX_LENGTH + 1) } }

    it 'reports the length' do
      expect(scheme.errors.sole[:detail])
        .to eq("i7 must not be longer than #{described_class::MAX_LENGTH} " \
               'characters')
    end
  end

  context 'with problems in both' do
    let(:fields) { { 'i7' => 'XX', 'i5' => 'YY' } }

    it 'reports each' do
      expect(scheme.errors.pluck(:pointer)).to eq(
        %w[/labware/0/receptacles/0/samples/0/i7
           /labware/0/receptacles/0/samples/0/i5]
      )
    end
  end

  describe '#oligos' do
    let(:fields) { { 'i7' => 'ACGT', 'i5' => 'ttga' } }

    it 'gives the i7 and i5 as given, for one aliquot' do
      expect(scheme.oligos(samples.first)).to eq([%w[ACGT ttga]])
    end

    it 'gives nil for an i5 not given' do
      expect(scheme.oligos(sample({ 'i7' => 'ACGT' }))).to eq([['ACGT', nil]])
    end
  end
end
