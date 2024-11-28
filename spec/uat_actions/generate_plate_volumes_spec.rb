# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GeneratePlateVolumes do
  context 'with valid options' do
    let(:plate) { create(:plate_with_untagged_wells, sample_count: 3) }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { 'number_well_volumes_written' => 3 }
    end

    context 'when ul volumes' do
      let(:parameters) { { plate_barcode: plate.barcodes.first.barcode, minimum_volume: 0, maximum_volume: 30 } }

      it 'can be performed' do
        expect(uat_action.perform).to be true
      end

      it 'generates the correct report' do
        expect(uat_action.report).to eq report
      end

      it 'creates the correct number of QC results' do
        expect(plate.wells.map(&:qc_results).size).to eq 3
      end

      it 'sets the correct assay type for the first QC result' do
        expect(plate.wells.first.qc_results.first.assay_type).to eq 'UAT_Testing'
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
