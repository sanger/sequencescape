# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'asset labels creator' do
  subject { described_class.new(assets) }

  let(:date) { Time.zone.today.strftime('%e-%^b-%Y').to_s }

  let(:labels) { body }

  it 'prints the correct labels' do
    expect(subject.labels).to eq(labels)
  end

  it 'returns the correct assets' do
    expect(subject.assets).to eq(assets)
  end
end

context 'printing plates' do
  let(:asset1) { create(:child_plate, name: 'Plate Name') }
  let(:asset2) { create(:child_plate, name: 'Plate Name') }
  let(:asset3) { create(:child_plate) }
  let(:assets) { [asset1, asset2, asset3] }

  describe LabelPrinter::Label::AssetPlate do
    let(:body) do
      assets.map do |asset|
        {
          top_left: date,
          bottom_left: asset.human_barcode.to_s,
          top_right: asset.plate_purpose.name.to_s,
          bottom_right: asset.studies.first&.abbreviation,
          top_far_right: asset.parent.try(:human_barcode).to_s,
          barcode: asset.machine_barcode.to_s,
          label_name: 'main_label'
        }
      end
    end

    it_behaves_like 'asset labels creator'
  end

  describe LabelPrinter::Label::AssetPlateDouble do
    let(:body) do
      assets.map do |asset|
        [
          {
            left_text: asset.human_barcode.to_s,
            right_text: "#{asset.prefix} #{asset.barcode_number}",
            barcode: asset.machine_barcode.to_s,
            label_name: 'main_label'
          },
          { left_text: date, right_text: asset.purpose.name, label_name: 'extra_label' }
        ]
      end.flatten
    end

    it_behaves_like 'asset labels creator'
  end
end

context 'printing tubes' do
  describe LabelPrinter::Label::AssetTube do
    let(:asset1) { create(:empty_sample_tube, barcode: '11111', name: 'Tube Name') }
    let(:asset2) { create(:empty_sample_tube) }
    let(:assets) { [asset1, asset2] }

    let(:body) do
      assets.map do |asset|
        {
          first_line: asset.name,
          second_line: asset.barcode_number,
          third_line: date,
          round_label_top_line: asset.prefix,
          round_label_bottom_line: asset.barcode_number,
          barcode: asset.machine_barcode,
          label_name: 'main_label'
        }
      end
    end

    it_behaves_like 'asset labels creator'
  end
end

context 'base plate' do
  it 'normal plate should output ean13 barcode' do
    plate = create(:plate)
    label = LabelPrinter::Label::AssetPlate.new([plate])
    expect(label.build_label(plate)[:barcode]).to eq(plate.machine_barcode)
  end
end
