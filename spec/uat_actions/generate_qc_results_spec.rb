# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateQcResults do
  context 'with valid options' do
    let(:plate) { create :plate_with_untagged_wells, sample_count: 3 }
    let(:tube) { create :sample_tube, barcode: '1' }

    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'number_results_written' => 3 }
    end

    context 'when concentration' do
      let(:parameters) do
        {
          labware_barcode: plate.human_barcode,
          measured_attribute: 'concentration',
          minimum_value: 0,
          maximum_value: 30
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report).to eq report
        expect(plate.wells.flat_map(&:qc_results).size).to eq 3
        expect(plate.wells.first.qc_results.first.assay_type).to eq 'UAT_Testing'
      end
    end

    context 'when a tube' do
      let(:parameters) do
        {
          labware_barcode: tube.human_barcode,
          measured_attribute: 'concentration',
          minimum_value: 0,
          maximum_value: 30
        }
      end
      let(:report) do
        # A report is a hash of key value pairs which get returned to the user.
        # It should include information such as barcodes and identifiers
        { 'number_results_written' => 1 }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report).to eq report
        expect(tube.receptacles.flat_map(&:qc_results).size).to eq 1
        expect(tube.receptacles.first.qc_results.first.assay_type).to eq 'UAT_Testing'
      end
    end

    context 'when molarity' do
      let(:parameters) do
        { labware_barcode: plate.human_barcode, measured_attribute: 'molarity', minimum_value: 0, maximum_value: 30 }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report).to eq report
        expect(plate.wells.map(&:qc_results).size).to eq 3
        expect(plate.wells.first.qc_results.first.assay_type).to eq 'UAT_Testing'
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
