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

  context 'with a barcode used twice' do
    let(:payload_labware) do
      [labware('PLATE-1', 0), labware('PLATE-2', 1), labware('PLATE-1', 2)]
    end

    it 'reports the second use' do
      expect(validation.errors).to eq(
        [{ pointer: '/labware/2/barcode',
           detail: 'Barcode PLATE-1 is also used by /labware/0' }]
      )
    end
  end

  context 'with a known labware whose barcode is used again' do
    let(:payload_labware) { [labware('PLATE-1', 0), labware('PLATE-1', 1)] }
    let(:new_labware) { [payload_labware.last] }

    it 'reports it too' do
      expect(validation.errors.sole[:pointer]).to eq('/labware/1/barcode')
    end
  end

  context 'with a tube without a receptacle' do
    let(:payload_labware) do
      [labware('TUBE-1', 0, type: 'tube', positions: [])]
    end

    it 'reports the receptacles' do
      expect(validation.errors).to eq(
        [{ pointer: '/labware/0/receptacles',
           detail: 'A tube has one receptacle, not 0' }]
      )
    end
  end

  context 'with a tube with two receptacles' do
    let(:payload_labware) do
      [labware('TUBE-1', 0, type: 'tube', positions: [nil, nil])]
    end

    it 'reports the receptacles' do
      expect(validation.errors.sole[:detail])
        .to eq('A tube has one receptacle, not 2')
    end
  end

  context "with a position on a tube's receptacle" do
    let(:payload_labware) do
      [labware('TUBE-1', 0, type: 'tube', positions: ['A1'])]
    end

    it 'reports the position' do
      expect(validation.errors).to eq(
        [{ pointer: '/labware/0/receptacles/0/position',
           detail: "A tube's receptacle has no position" }]
      )
    end
  end

  context 'with a plate position that is not a well of its size' do
    let(:payload_labware) { [labware('PLATE-1', 0, positions: %w[A1 A13])] }

    it 'reports the position' do
      expect(validation.errors).to eq(
        [{ pointer: '/labware/0/receptacles/1/position',
           detail: 'A13 is not a well of a 96-well plate' }]
      )
    end
  end

  context 'with a well of a 384-well plate' do
    let(:payload_labware) do
      [labware('PLATE-1', 0, type: 'plate384', positions: %w[P24])]
    end

    it 'accepts it' do
      expect(validation.errors).to be_empty
    end
  end

  context 'with a well listed twice' do
    let(:payload_labware) { [labware('PLATE-1', 0, positions: %w[A1 B1 A1])] }

    it 'reports the second listing' do
      expect(validation.errors).to eq(
        [{ pointer: '/labware/0/receptacles/2/position',
           detail: 'Well A1 is listed more than once' }]
      )
    end
  end

  context 'with a well without a position' do
    let(:payload_labware) { [labware('PLATE-1', 0, positions: [nil])] }

    it 'reports the position' do
      expect(validation.errors.sole[:detail]).to eq('A well needs a position')
    end
  end

  context 'with known labware' do
    let(:payload_labware) { [labware('PLATE-1', 0, positions: %w[Z99])] }
    let(:new_labware) { [] }

    it 'leaves its positions to the reconciliation' do
      expect(validation.errors).to be_empty
    end
  end

  context 'with several problems' do
    let(:payload_labware) do
      [labware('PLATE-1', 0, positions: %w[A13]),
       labware('PLATE-1', 1, type: 'tube', positions: [])]
    end

    it 'reports them all' do
      expect(validation.errors.pluck(:pointer)).to contain_exactly(
        '/labware/1/barcode', '/labware/0/receptacles/0/position',
        '/labware/1/receptacles'
      )
    end
  end

  describe 'studies' do
    let(:study) { create(:study) }
    let(:unknown) { SecureRandom.uuid }
    let(:other_unknown) { SecureRandom.uuid }

    context 'with existing studies' do
      let(:payload_labware) do
        [plate_with_studies('PLATE-1', 0, [study.uuid, study.uuid])]
      end

      it 'finds no errors' do
        expect(validation.errors).to be_empty
      end
    end

    context 'with a study used by several samples that does not exist' do
      let(:payload_labware) do
        [plate_with_studies('PLATE-1', 0, [study.uuid, unknown, unknown])]
      end

      it 'reports it once, at its first sample, with how many use it' do
        expect(validation.errors).to eq(
          [{ pointer: '/labware/0/receptacles/1/samples/0/study_uuid',
             detail: "No study with UUID #{unknown} (used by 2 samples)" }]
        )
      end
    end

    context 'with two studies that do not exist' do
      let(:payload_labware) do
        [plate_with_studies('PLATE-1', 0, [unknown]),
         plate_with_studies('PLATE-2', 1, [other_unknown])]
      end

      it 'reports each' do
        expect(validation.errors.pluck(:detail)).to eq(
          ["No study with UUID #{unknown} (used by 1 sample)",
           "No study with UUID #{other_unknown} (used by 1 sample)"]
        )
      end
    end

    context 'with known labware' do
      let(:payload_labware) { [plate_with_studies('PLATE-1', 0, [unknown])] }
      let(:new_labware) { [] }

      it 'does not check its samples' do
        expect(validation.errors).to be_empty
      end
    end
  end
end
