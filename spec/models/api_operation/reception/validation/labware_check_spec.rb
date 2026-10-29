# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Validation::LabwareCheck do
  subject(:check) { described_class.new(input) }

  let(:input) do
    ApiOperation::Reception::Validation::Input.build(payload_labware,
                                                     new_labware)
  end

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

  context 'with a valid plate and tube' do
    let(:payload_labware) do
      [labware('PLATE-1', 0, positions: %w[A1 H12]),
       labware('TUBE-1', 1, type: 'tube', positions: [nil])]
    end

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a barcode used twice' do
    let(:payload_labware) do
      [labware('PLATE-1', 0), labware('PLATE-2', 1), labware('PLATE-1', 2)]
    end

    it 'reports the second use' do
      expect(check.errors).to eq(
        [{ pointer: '/labware/2/barcode',
           detail: 'Barcode PLATE-1 is also used by /labware/0' }]
      )
    end
  end

  context 'with a known labware whose barcode is used again' do
    let(:payload_labware) { [labware('PLATE-1', 0), labware('PLATE-1', 1)] }
    let(:new_labware) { [payload_labware.last] }

    it 'reports it too' do
      expect(check.errors.sole[:pointer]).to eq('/labware/1/barcode')
    end
  end

  context 'with a tube without a receptacle' do
    let(:payload_labware) do
      [labware('TUBE-1', 0, type: 'tube', positions: [])]
    end

    it 'reports the receptacles' do
      expect(check.errors).to eq(
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
      expect(check.errors.sole[:detail])
        .to eq('A tube has one receptacle, not 2')
    end
  end

  context "with a position on a tube's receptacle" do
    let(:payload_labware) do
      [labware('TUBE-1', 0, type: 'tube', positions: ['A1'])]
    end

    it 'reports the position' do
      expect(check.errors).to eq(
        [{ pointer: '/labware/0/receptacles/0/position',
           detail: "A tube's receptacle has no position" }]
      )
    end
  end

  context 'with a plate position that is not a well of its size' do
    let(:payload_labware) { [labware('PLATE-1', 0, positions: %w[A1 A13])] }

    it 'reports the position' do
      expect(check.errors).to eq(
        [{ pointer: '/labware/0/receptacles/1/position',
           detail: 'A13 is not a well of a 96-well plate' }]
      )
    end
  end

  context 'with a new 384-well plate' do
    let(:payload_labware) do
      [labware('PLATE-1', 0, type: 'plate384', positions: %w[P24 Z99])]
    end

    it 'reports the type, and not its positions' do
      expect(check.errors).to eq(
        [{ pointer: '/labware/0/type',
           detail: '384-well plates are not supported by reception yet' }]
      )
    end
  end

  context 'with a known 384-well plate' do
    let(:payload_labware) do
      [labware('PLATE-1', 0, type: 'plate384', positions: %w[P24])]
    end
    let(:new_labware) { [] }

    it 'finds no errors' do
      expect(check.errors).to be_empty
    end
  end

  context 'with a well listed twice' do
    let(:payload_labware) { [labware('PLATE-1', 0, positions: %w[A1 B1 A1])] }

    it 'reports the second listing' do
      expect(check.errors).to eq(
        [{ pointer: '/labware/0/receptacles/2/position',
           detail: 'Well A1 is listed more than once' }]
      )
    end
  end

  context 'with a well without a position' do
    let(:payload_labware) { [labware('PLATE-1', 0, positions: [nil])] }

    it 'reports the position' do
      expect(check.errors.sole[:detail]).to eq('A well needs a position')
    end
  end

  context 'with known labware' do
    let(:payload_labware) { [labware('PLATE-1', 0, positions: %w[Z99])] }
    let(:new_labware) { [] }

    it 'leaves its positions to the reconciliation' do
      expect(check.errors).to be_empty
    end
  end

  context 'with several problems' do
    let(:payload_labware) do
      [labware('PLATE-1', 0, positions: %w[A13]),
       labware('PLATE-1', 1, type: 'tube', positions: [])]
    end

    it 'reports them all' do
      expect(check.errors.pluck(:pointer)).to contain_exactly(
        '/labware/1/barcode', '/labware/0/receptacles/0/position',
        '/labware/1/receptacles'
      )
    end
  end
end
