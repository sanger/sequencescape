# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GeneratePlates do
  context 'with valid options' do
    let(:study) { create(:study, name: 'Test Study') }
    let(:uat_action) { described_class.new(parameters) }
    let(:plate_barcode_1) { build(:plate_barcode) }
    let(:plate_barcode_2) { build(:plate_barcode) }
    let(:plate_barcode_3) { build(:plate_barcode) }

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
        { 'plate_0' => plate_barcode_1[:barcode] }
      end

      before { allow(PlateBarcode).to receive(:create_barcode).and_return(plate_barcode_1) }

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
        { 'plate_0' => plate_barcode_1[:barcode], 'plate_1' => plate_barcode_2[:barcode], 'plate_2' => plate_barcode_3[:barcode] }
      end

      before { allow(PlateBarcode).to receive(:create_barcode).and_return(plate_barcode_1, plate_barcode_2, plate_barcode_3)}

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
