# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateTubes do
  context 'with valid options' do
    let(:study) { create(:study, name: 'Test Study') }
    let(:uat_action) { described_class.new(parameters) }

    context 'when creating a single tube' do
      let(:parameters) do
        { tube_purpose_name: Tube::Purpose.standard_sample_tube.name, tube_count: 1, study_name: study.name }
      end
      let(:report) do
        # A report is a hash of key value pairs which get returned to the user.
        # It should include information such as barcodes and identifiers
        { 'tube_0' => 'NT2P' }
      end

      before { allow(AssetBarcode).to receive(:new_barcode).and_return('2') }

      it 'performs the action successfully' do
        expect(uat_action.perform).to be true
      end

      it 'returns the expected barcode in the report' do
        uat_action.perform
        expect(uat_action.report['tube_0']).to eq report['tube_0']
      end

      it 'assigns the correct study to the tube' do
        uat_action.perform
        tube = Tube.find_by_barcode(report['tube_0'])
        expect(tube.aliquots.first.study).to eq study
      end

      it 'sets the correct sample metadata values' do
        uat_action.perform
        tube = Tube.find_by_barcode(report['tube_0'])
        sample_metadata = tube.aliquots.first.sample.sample_metadata
        expect(sample_metadata).to have_attributes(
          supplier_name: 'sample_NT2P_0',
          collected_by: UatActions::StaticRecords.collection_site,
          donor_id: 'sample_NT2P_0_donor',
          sample_common_name: 'human'
        )
      end
    end

    context 'when creating multiple tubes' do
      let(:parameters) do
        { tube_purpose_name: Tube::Purpose.standard_sample_tube.name, tube_count: 3, study_name: study.name }
      end
      let(:report) do
        # A report is a hash of key value pairs which get returned to the user.
        # It should include information such as barcodes and identifiers
        { 'tube_0' => 'NT3Q', 'tube_1' => 'NT4R', 'tube_2' => 'NT5S' }
      end

      before { allow(AssetBarcode).to receive(:new_barcode).and_return('3', '4', '5') }

      it 'performs the action successfully' do
        expect(uat_action.perform).to be true
      end

      it 'returns the expected barcodes in the report' do
        uat_action.perform
        expect(uat_action.report['tube_0']).to eq report['tube_0']
        expect(uat_action.report['tube_1']).to eq report['tube_1']
        expect(uat_action.report['tube_2']).to eq report['tube_2']
      end

      it 'sets the correct sample metadata values for each tube' do
        uat_action.perform
        uat_action.report.each_with_index do |(_key, barcode), i|
          sample_metadata = Tube.find_by_barcode(barcode).aliquots.first.sample.sample_metadata
          expect(sample_metadata).to have_attributes(
            supplier_name: "sample_#{barcode}_#{i}",
            collected_by: UatActions::StaticRecords.collection_site,
            donor_id: "sample_#{barcode}_#{i}_donor",
            sample_common_name: 'human'
          )
        end
      end
    end

    context 'when creating the tube with a fluidx foreign barcode' do
      let(:parameters) do
        {
          tube_purpose_name: Tube::Purpose.standard_sample_tube.name,
          tube_count: 1,
          study_name: study.name,
          foreign_barcode_type: 'FluidX'
        }
      end
      let(:expected_report) do
        # Tube NT6T created with foreign barcode based on machine barcode
        { 'tube_0' => 'SA00006844' }
      end

      before { allow(AssetBarcode).to receive(:new_barcode).and_return('6') }

      it 'performs the action successfully' do
        expect(uat_action.perform).to be true
      end

      it 'returns the expected barcode in the report' do
        uat_action.perform
        expect(uat_action.report['tube_0']).to eq expected_report['tube_0']
      end

      it 'assigns the correct study to the tube' do
        uat_action.perform
        tube = Tube.find_by_barcode(expected_report['tube_0'])
        expect(tube.aliquots.first.study).to eq study
      end

      it 'sets the correct sample metadata values' do
        uat_action.perform
        tube = Tube.find_by_barcode(expected_report['tube_0'])
        sample_metadata = tube.aliquots.first.sample.sample_metadata
        expect(sample_metadata).to have_attributes(
          supplier_name: 'sample_NT6T_0',
          collected_by: UatActions::StaticRecords.collection_site,
          donor_id: 'sample_NT6T_0_donor',
          sample_common_name: 'human'
        )
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
