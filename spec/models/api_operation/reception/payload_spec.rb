# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Payload do
  subject(:payload) { described_class.new(body.to_json) }

  let(:sample) do
    { uuid: '33333333-3333-4333-8333-333333333333',
      study_uuid: '44444444-4444-4444-8444-444444444444',
      sanger_sample_id: 'SAMPLE-1',
      supplier_sample_name: 'Supplier sample 1' }
  end
  let(:tagged_sample) do
    sample.merge(uuid: '55555555-5555-4555-8555-555555555555',
                 sanger_sample_id: 'SAMPLE-2',
                 i7: 'ACGTACGT', library_type: 'Standard')
  end
  let(:plate) do
    { uuid: '11111111-1111-4111-8111-111111111111',
      barcode: 'PLATE-1',
      type: 'plate96',
      receptacles: [
        { position: 'A1', uuid: '22222222-2222-4222-8222-222222222221',
          samples: [sample] },
        { position: 'B1', uuid: '22222222-2222-4222-8222-222222222222',
          samples: [tagged_sample] }
      ] }
  end
  let(:tube) do
    { uuid: '66666666-6666-4666-8666-666666666666',
      barcode: 'TUBE-1',
      type: 'tube',
      receptacles: [
        { position: nil, uuid: '77777777-7777-4777-8777-777777777777',
          samples: [sample, tagged_sample] }
      ] }
  end
  let(:body) do
    { request: { external_id: 'request-1' },
      work_order: { external_id: 'work-order-1' },
      labware: [plate, tube] }
  end

  let(:plate_labware) { payload.labware.first }
  let(:tube_labware) { payload.labware.last }

  it 'reads the labware in payload order' do
    expect(payload.labware.map(&:barcode)).to eq(%w[PLATE-1 TUBE-1])
  end

  it 'reads a plate' do
    expect(plate_labware).to have_attributes(
      uuid: '11111111-1111-4111-8111-111111111111',
      barcode: 'PLATE-1',
      type: 'plate96',
      pointer: '/labware/0'
    )
  end

  it 'reads its wells' do
    expect(plate_labware.receptacles.map { [it.position, it.pointer] }).to eq(
      [%w[A1 /labware/0/receptacles/0], %w[B1 /labware/0/receptacles/1]]
    )
  end

  it "reads a well's receptacle UUID" do
    expect(plate_labware.receptacles.first.uuid)
      .to eq('22222222-2222-4222-8222-222222222221')
  end

  it 'reads a tube, whose receptacle has no position' do
    receptacle = tube_labware.receptacles.sole
    expect(receptacle).to have_attributes(position: nil,
                                          pointer: '/labware/1/receptacles/0')
  end

  it 'reads the samples in a receptacle, in payload order' do
    samples = tube_labware.receptacles.sole.samples
    expect(samples.map(&:sanger_sample_id)).to eq(%w[SAMPLE-1 SAMPLE-2])
  end

  it 'reads a sample' do
    expect(plate_labware.receptacles.first.samples.sole).to have_attributes(
      uuid: '33333333-3333-4333-8333-333333333333',
      study_uuid: '44444444-4444-4444-8444-444444444444',
      sanger_sample_id: 'SAMPLE-1',
      supplier_sample_name: 'Supplier sample 1',
      pointer: '/labware/0/receptacles/0/samples/0'
    )
  end

  it 'gives a sample without optional keys no fields' do
    expect(plate_labware.receptacles.first.samples.sole.fields).to eq({})
  end

  it "keeps a sample's optional keys as fields, by their payload names" do
    expect(plate_labware.receptacles.last.samples.sole.fields)
      .to eq('i7' => 'ACGTACGT', 'library_type' => 'Standard')
  end

  it 'points to a sample in a tube' do
    expect(tube_labware.receptacles.sole.samples.last.pointer)
      .to eq('/labware/1/receptacles/0/samples/1')
  end

  it 'raises if a required key is missing' do
    body[:labware].first.delete(:barcode)
    expect { payload.labware }.to raise_error(KeyError)
  end

  context 'with a sample UUID in upper case' do
    let(:sample) { super().merge(uuid: '3F2504E0-4F89-41D3-9A0C-0305E82C3301') }

    it 'reads it in lower case' do
      expect(plate_labware.receptacles.first.samples.sole.uuid)
        .to eq('3f2504e0-4f89-41d3-9a0c-0305e82c3301')
    end
  end

  context 'with a study UUID in upper case' do
    let(:sample) do
      super().merge(study_uuid: '3F2504E0-4F89-41D3-9A0C-0305E82C3301')
    end

    it 'reads it in lower case' do
      expect(plate_labware.receptacles.first.samples.sole.study_uuid)
        .to eq('3f2504e0-4f89-41d3-9a0c-0305e82c3301')
    end
  end
end
