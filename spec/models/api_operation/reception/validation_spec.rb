# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation do
  subject(:validation) { described_class.new(payload_labware, new_labware) }

  let(:new_labware) { payload_labware }

  def labware(barcode, index, type: 'plate96', positions: ['A1'])
    pointer = "/labware/#{index}"
    receptacles =
      positions.each_with_index.map do |position, receptacle_index|
        ApiOperation::Reception::Payload::PayloadReceptacle.new(
          position: position, uuid: SecureRandom.uuid, samples: [],
          pointer: "#{pointer}/receptacles/#{receptacle_index}"
        )
      end
    ApiOperation::Reception::Payload::PayloadLabware.new(
      uuid: SecureRandom.uuid, barcode: barcode, type: type,
      receptacles: receptacles, pointer: pointer
    )
  end

  # A plate with one sample in each well, A1 onwards, with the study UUIDs
  def plate_with_studies(barcode, index, study_uuids)
    pointer = "/labware/#{index}"
    receptacles =
      study_uuids.each_with_index.map do |study_uuid, well_index|
        receptacle_pointer = "#{pointer}/receptacles/#{well_index}"
        sample =
          sample_with_study(study_uuid, "#{receptacle_pointer}/samples/0")
        ApiOperation::Reception::Payload::PayloadReceptacle.new(
          position: "#{('A'..'H').to_a[well_index]}1", uuid: SecureRandom.uuid,
          samples: [sample], pointer: receptacle_pointer
        )
      end
    ApiOperation::Reception::Payload::PayloadLabware.new(
      uuid: SecureRandom.uuid, barcode: barcode, type: 'plate96',
      receptacles: receptacles, pointer: pointer
    )
  end

  def sample_with_study(study_uuid, pointer)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: study_uuid,
      sanger_sample_id: "SAMPLE-#{SecureRandom.hex(4)}",
      supplier_sample_name: 'Supplier sample', fields: {}, pointer: pointer
    )
  end

  context 'with a valid plate and tube' do
    let(:payload_labware) do
      [labware('PLATE-1', 0, positions: %w[A1 H12]),
       labware('TUBE-1', 1, type: 'tube', positions: [nil])]
    end

    it 'finds no errors' do
      expect(validation.errors).to be_empty
    end
  end

  context 'with a labware problem and a sample problem' do
    let(:payload_labware) do
      [plate_with_studies('PLATE-1', 0, [SecureRandom.uuid]),
       labware('PLATE-1', 1)]
    end

    it 'reports the labware problem first' do
      expect(validation.errors.pluck(:pointer)).to eq(
        ['/labware/1/barcode',
         '/labware/0/receptacles/0/samples/0/study_uuid']
      )
    end
  end

  describe 'samples' do
    let(:study) { create(:study) }
    let(:unknown) { SecureRandom.uuid }

    context 'with valid samples in new labware' do
      let(:payload_labware) do
        [plate_with_studies('PLATE-1', 0, [study.uuid, study.uuid])]
      end

      it 'finds no errors' do
        expect(validation.errors).to be_empty
      end
    end

    context 'with a problem in a sample in new labware' do
      let(:payload_labware) { [plate_with_studies('PLATE-1', 0, [unknown])] }

      it 'reports it' do
        expect(validation.errors.sole[:pointer])
          .to eq('/labware/0/receptacles/0/samples/0/study_uuid')
      end
    end

    context 'with a problem in a sample in known labware' do
      let(:payload_labware) { [plate_with_studies('PLATE-1', 0, [unknown])] }
      let(:new_labware) { [] }

      it 'does not check its samples' do
        expect(validation.errors).to be_empty
      end
    end
  end
end
