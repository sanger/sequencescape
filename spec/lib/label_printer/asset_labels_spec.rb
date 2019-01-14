# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'asset labels creator' do
  subject { described_class.new(assets) }

  let(:date) { Time.zone.today.strftime('%e-%^b-%Y').to_s }

  let(:labels) do
    { labels: { body: body } }
  end

  it 'prints the correct labels' do
    expect(subject.to_h).to eq(labels)
  end

  it 'returns the correct assets' do
    expect(subject.assets).to eq(assets)
  end
end

context 'printing plates' do
  let(:asset1) { create :child_plate, barcode: '11111', name: 'Plate Name' }
  let(:asset2) { create :child_plate, barcode: '22222', name: 'Plate Name' }
  let(:asset3) { create :child_plate, barcode: '33333' }
  let(:assets) { [asset1, asset2, asset3] }

  describe LabelPrinter::Label::AssetPlate do
    let(:body) do
      assets.map do |asset|
        { main_label:
          { top_left: date,
            bottom_left: asset.human_barcode.to_s,
            top_right: "#{asset.prefix} #{asset.barcode_number}",
            bottom_right: "#{asset.name_for_label} #{asset.barcode_number}",
            top_far_right: nil,
            barcode: asset.ean13_barcode.to_s } }
      end
    end

    it_behaves_like 'asset labels creator'
  end

  describe LabelPrinter::Label::AssetPlateDouble do
    let(:body) do
      assets.map do |asset|
        [{ main_label:
           { left_text: asset.human_barcode.to_s,
             right_text: "#{asset.prefix} #{asset.barcode_number}",
             barcode: asset.ean13_barcode.to_s } },
         { extra_label:
           { left_text: date,
             right_text: asset.purpose.name } }]
      end.flatten
    end

    it_behaves_like 'asset labels creator'
  end
end

context 'printing tubes' do
  describe LabelPrinter::Label::AssetTube do
    let(:asset1) { create :empty_sample_tube, barcode: '11111', name: 'Tube Name' }
    let(:asset2) { create :empty_sample_tube }
    let(:assets) { [asset1, asset2] }

    let(:body) do
      assets.map do |asset|
        { main_label:
        { top_line: asset.name,
          middle_line: asset.barcode_number,
          bottom_line: date,
          round_label_top_line: asset.prefix,
          round_label_bottom_line: asset.barcode_number,
          barcode: asset.ean13_barcode.to_s } }
      end
    end

    it_behaves_like 'asset labels creator'
  end
end

context 'base plate' do
  it 'normal plate should output ean13 barcode' do
    plate = create(:plate)
    label = LabelPrinter::Label::AssetPlate.new([plate])
    expect(label.create_label(plate)[:barcode]).to eq(plate.ean13_barcode)
  end

  xit 'working dilution plate should output human readable barcode' do
    plate = create(:working_dilution_plate)
    label = LabelPrinter::Label::AssetPlate.new([plate])
    expect(label.create_label(plate)[:barcode]).to eq(plate.human_barcode)
  end
end
