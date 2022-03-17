# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GeneratePlates do
  context 'with valid options' do
    let(:study) { create(:study, name: 'Test Study') }
    let(:uat_action) { described_class.new(parameters) }

    context 'when creating a single plate' do
      let(:parameters) do
        {
          plate_purpose_name: PlatePurpose.stock_plate_purpose.name,
          plate_count: 1,
          well_count: 1,
          study_name: study.name,
          well_layout: 'Column'
        }
      end
      let(:report) do
        # A report is a hash of key value pairs which get returned to the user.
        # It should include information such as barcodes and identifiers
        { 'plate_0' => 'DN2T' }
      end
      let(:barcode_1) { build(:plate_barcode, barcode: 2) }

      before { allow(PlateBarcode).to receive(:create).and_return(barcode_1) }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_0']).to eq report['plate_0']
        expect(Plate.find_by_barcode(report['plate_0']).wells.first.aliquots.first.study).to eq study
      end
    end

    context 'when creating multiple plates' do
      let(:parameters) do
        {
          plate_purpose_name: PlatePurpose.stock_plate_purpose.name,
          plate_count: 3,
          well_count: 1,
          study_name: study.name,
          well_layout: 'Column'
        }
      end
      let(:report) do
        # A report is a hash of key value pairs which get returned to the user.
        # It should include information such as barcodes and identifiers
        { 'plate_0' => 'DN3U', 'plate_1' => 'DN4V', 'plate_2' => 'DN5W' }
      end
      let(:barcode_1) { build(:plate_barcode, barcode: 3) }
      let(:barcode_2) { build(:plate_barcode, barcode: 4) }
      let(:barcode_3) { build(:plate_barcode, barcode: 5) }

      before { allow(PlateBarcode).to receive(:create).and_return(barcode_1, barcode_2, barcode_3) }

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report['plate_0']).to eq report['plate_0']
        expect(uat_action.report['plate_1']).to eq report['plate_1']
        expect(uat_action.report['plate_2']).to eq report['plate_2']
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
