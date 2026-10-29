# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::Input do
  subject(:input) { described_class.build(payload_labware, new_labware) }

  def sample(index)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: "SAMPLE-#{index}",
      supplier_sample_name: "Supplier sample #{index}", fields: {},
      pointer: "/labware/0/receptacles/#{index}/samples/0"
    )
  end

  def labware(barcode, samples_by_well)
    receptacles =
      samples_by_well.map do |samples|
        ApiOperation::Reception::Payload::PayloadReceptacle.new(
          position: nil, uuid: SecureRandom.uuid, samples: samples,
          pointer: '/labware/0/receptacles/0'
        )
      end
    ApiOperation::Reception::Payload::PayloadLabware.new(
      uuid: SecureRandom.uuid, barcode: barcode, type: 'plate96',
      receptacles: receptacles, pointer: '/labware/0'
    )
  end

  let(:replicated) { sample(0) }
  let(:other) { sample(1) }
  let(:new_plate) { labware('NEW-1', [[replicated], [replicated, other]]) }
  let(:known_plate) { labware('KNOWN-1', [[sample(2)]]) }
  let(:payload_labware) { [new_plate, known_plate] }
  let(:new_labware) { [new_plate] }

  it 'keeps all the labware' do
    expect(input.payload_labware).to eq(payload_labware)
  end

  it 'keeps the new labware' do
    expect(input.new_labware).to eq(new_labware)
  end

  it "lists the new labware's samples, an entry for each receptacle" do
    expect(input.new_samples).to eq([replicated, replicated, other])
  end
end
