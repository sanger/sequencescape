# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateTaggedPlates do
  context 'with valid options' do
    let(:study) { create(:study, name: 'Test Study') }
    let(:tag_group) { create(:tag_group, tag_count: 2) }
    let(:tag_group2) { create(:tag_group, tag_count: 2) }
    let(:uat_action) { described_class.new(parameters) }
    let(:plate_barcode_1) { build(:plate_barcode) }
    let(:plate_barcode_2) { build(:plate_barcode) }
    let(:plate_barcode_3) { build(:plate_barcode) }

    context 'when creating a single plate' do
      let(:parameters) do
        {
          plate_purpose_name: PlatePurpose.stock_plate_purpose.name,
          plate_count: 1,
          well_count: 2,
          study_name: study.name,
          well_layout: 'Column',
          tag_group_name: tag_group.name,
          tag2_group_name: tag_group2.name,
          direction: 'column',
          walking_by: 'wells of plate'
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
      end

      it 'tags the plate' do
        expect { uat_action.perform }.to change(TagLayout, :count).by 1
        expect(Plate.find_by_barcode(report['plate_0']).aliquots.first.tag.tag_group).to eq tag_group
        expect(Plate.find_by_barcode(report['plate_0']).aliquots.first.tag2.tag_group).to eq tag_group2
      end
    end

    context 'when creating multiple plates' do
      let(:parameters) do
        {
          plate_purpose_name: PlatePurpose.stock_plate_purpose.name,
          plate_count: 3,
          well_count: 1,
          study_name: study.name,
          well_layout: 'Column',
          tag_group_name: tag_group.name,
          tag2_group_name: tag_group2.name,
          direction: 'column',
          walking_by: 'wells of plate'
        }
      end
      let(:report) do
        # A report is a hash of key value pairs which get returned to the user.
        # It should include information such as barcodes and identifiers
        {
          'plate_0' => plate_barcode_1[:barcode],
          'plate_1' => plate_barcode_2[:barcode],
          'plate_2' => plate_barcode_3[:barcode]
        }
      end

      before do
        allow(PlateBarcode).to receive(:create_barcode).and_return(plate_barcode_1, plate_barcode_2, plate_barcode_3)
      end

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
