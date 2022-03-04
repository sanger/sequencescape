# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateTaggedPlates do
  context 'with valid options' do
    let(:study) { create(:study, name: 'Test Study') }
    let(:tag_group) { create(:tag_group, tag_count: 2) }
    let(:tag_group2) { create(:tag_group, tag_count: 2) }
    let(:uat_action) { described_class.new(parameters) }

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
        { 'plate_0' => 'DN2T' }
      end

      let(:barcode_1) { build(:plate_barcode, barcode: 2) }

      before { allow(PlateBarcode).to receive(:create).and_return(barcode_1) }

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
