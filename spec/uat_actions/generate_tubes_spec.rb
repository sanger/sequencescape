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

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['tube_0']).to eq report['tube_0']
        expect(Tube.find_by_barcode(report['tube_0']).aliquots.first.study).to eq study
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

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['tube_0']).to eq report['tube_0']
        expect(uat_action.report['tube_1']).to eq report['tube_1']
        expect(uat_action.report['tube_2']).to eq report['tube_2']
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
      let(:report) do
        # Tube NT6T created with foreign barcode based on machine barcode
        { 'tube_0' => 'SA00006844' }
      end

      before { allow(AssetBarcode).to receive(:new_barcode).and_return('6') }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['tube_0']).to eq report['tube_0']
        expect(Tube.find_by_barcode(report['tube_0']).aliquots.first.study).to eq study
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
