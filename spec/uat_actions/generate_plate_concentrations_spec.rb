# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GeneratePlateConcentrations do
  context 'with valid options' do
    let(:plate) { create :plate_with_untagged_wells, sample_count: 3, barcode: '1' }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'number_well_concentrations_written' => 3 }
    end

    context 'when ng per ul concentrations' do
      let(:parameters) do
        {
          plate_barcode: plate.barcodes.first.barcode,
          concentration_units: 'ng/ul',
          minimum_concentration: 0,
          maximum_concentration: 30
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report).to eq report
        expect(plate.wells.map(&:qc_results).size).to eq 3
        expect(plate.wells.first.qc_results.first.assay_type).to eq 'UAT_Testing'
      end
    end

    context 'when nM concentrations' do
      let(:parameters) do
        {
          plate_barcode: plate.barcodes.first.barcode,
          concentration_units: 'nM',
          minimum_concentration: 0,
          maximum_concentration: 30
        }
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
