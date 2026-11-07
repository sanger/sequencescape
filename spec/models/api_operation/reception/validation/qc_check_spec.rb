# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::QcCheck do
  subject(:check) { described_class.new(input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.build(labware, labware)
  end

  # The entry of the sample at the index in the receptacle at the index,
  # with the optional fields given
  def entry(uuid, receptacle_index, sample_index, **fields)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: "SAMPLE-#{uuid}",
      supplier_sample_name: "Supplier sample #{uuid}",
      fields: fields.transform_keys(&:to_s),
      pointer: "/labware/0/receptacles/#{receptacle_index}/samples/" \
               "#{sample_index}"
    )
  end

  # A plate with a well for each list of entries, from A1 down the first
  # column
  def plate_with(*entries_by_well)
    receptacles = entries_by_well.each_with_index.map do |entries, index|
      ApiOperation::Reception::Payload::PayloadReceptacle.new(
        position: "#{('A'.ord + index).chr}1", uuid: SecureRandom.uuid,
        samples: entries, pointer: "/labware/0/receptacles/#{index}"
      )
    end
    [ApiOperation::Reception::Payload::PayloadLabware.new(
      uuid: SecureRandom.uuid, barcode: 'PLATE-1', type: 'plate96',
      receptacles: receptacles, pointer: '/labware/0'
    )]
  end

  # The detail of the error for the sample and the fields it gives
  def detail(uuid, fields)
    "Sample #{uuid} gives a #{fields} that can't be stored: it is in more " \
      'than one receptacle, and this one holds other samples'
  end

  context 'with a pool whose samples are each in it once' do
    let(:labware) do
      plate_with([entry('S1', 0, 0, volume: 10, concentration: 4.2),
                  entry('S2', 0, 1, volume: 12, concentration: 3.8)])
    end

    it 'finds no errors, as the samples keep their values' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a sample alone in two wells' do
    let(:labware) do
      plate_with([entry('S1', 0, 0, volume: 20, concentration: 15.5)],
                 [entry('S1', 1, 0, volume: 15, concentration: 12.0)])
    end

    it 'finds no errors, as the wells keep their values' do
      expect(check.errors).to be_empty
    end
  end

  context 'with samples in two pools that give volumes and concentrations' do
    let(:labware) do
      plate_with([entry('S1', 0, 0, volume: 10, concentration: 4.2),
                  entry('S2', 0, 1)],
                 [entry('S1', 1, 0, volume: 10),
                  entry('S2', 1, 1, concentration: 3.8)])
    end

    it 'reports each entry that gives one, with the fields it gives' do
      expect(check.errors).to eq(
        [{ pointer: '/labware/0/receptacles/0/samples/0',
           detail: detail('S1', 'volume and concentration') },
         { pointer: '/labware/0/receptacles/1/samples/0',
           detail: detail('S1', 'volume') },
         { pointer: '/labware/0/receptacles/1/samples/1',
           detail: detail('S2', 'concentration') }]
      )
    end
  end

  context 'with samples in two pools that give no volume or concentration' do
    let(:labware) do
      plate_with([entry('S1', 0, 0), entry('S2', 0, 1)],
                 [entry('S1', 1, 0), entry('S2', 1, 1)])
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a sample alone in a well and in a pool' do
    let(:labware) do
      plate_with([entry('S1', 0, 0, volume: 20)],
                 [entry('S1', 1, 0, volume: 10), entry('S2', 1, 1)])
    end

    it 'reports only its entry in the pool' do
      expect(check.errors).to eq(
        [{ pointer: '/labware/0/receptacles/1/samples/0',
           detail: detail('S1', 'volume') }]
      )
    end
  end
end
