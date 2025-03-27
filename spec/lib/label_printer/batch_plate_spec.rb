# frozen_string_literal: true

require 'rails_helper'

shared_examples 'a correct single label printer' do
  it 'produces the correct label' do
    expected_labels = [
      {
        barcode: plate1.machine_barcode,
        bottom_left: plate1.human_barcode,
        bottom_right: "#{batch.output_plate_role} #{batch.output_plate_purpose.name} #{plate1.barcode_number}",
        top_far_right: nil,
        top_left: date_today,
        top_right: batch.studies.first.abbreviation,
        label_name: 'main_label'
      }
    ]
    expect(subject.labels).to eq(expected_labels)
  end
end

shared_examples 'a correct double label printer' do
  it 'produces the correct label' do
    expected_labels = [
      {
        left_text: plate1.human_barcode.to_s,
        right_text: plate1.barcode_number.to_s,
        barcode: plate1.machine_barcode,
        label_name: 'main_label'
      },
      {
        left_text: date_today,
        right_text:
          # rubocop:todo Layout/LineLength
          "#{batch.output_plate_role} #{batch.output_plate_purpose.name} #{plate1.barcode_number} #{batch.studies.first.abbreviation}",
        # rubocop:enable Layout/LineLength
        label_name: 'extra_label'
      }
    ]
    expect(subject.labels).to eq(expected_labels)
  end
end

shared_examples 'a correct multi-copy printer' do
  let(:count) { '3' }

  it 'prints multiple copies' do
    expect(subject.create_labels.count).to eq(expected_count)
  end
end

shared_examples 'a correct filter' do
  let(:printables) { { plate1.human_barcode => 'on', plate2.human_barcode => 'on' } }

  it 'has the correct plates' do
    expect(subject.assets).to eq([plate1, plate2])
  end
end

context 'printing labels' do
  subject { described_class.new(label_options) }

  let(:count) { '1' }
  let(:date_today) { Time.zone.today.strftime('%e-%^b-%Y') }
  let(:batch) { create(:batch) }
  let(:study) { create(:study) }
  let(:request1) do
    order =
      create(:order, order_role: OrderRole.new(role: 'test_role'), study: study, assets: [create(:empty_sample_tube)])
    create(
      :well_request,
      asset: create(:well_with_sample_and_plate),
      target_asset: create(:well_with_sample_and_plate),
      order: order
    )
  end
  let(:request2) do
    order =
      create(:order, order_role: OrderRole.new(role: 'test_role'), study: study, assets: [create(:empty_sample_tube)])
    create(
      :well_request,
      asset: create(:well_with_sample_and_plate),
      target_asset: create(:well_with_sample_and_plate),
      order: order
    )
  end
  let(:plate1) { request1.target_asset.plate }
  let(:plate2) { request2.target_asset.plate }
  let(:printables) { { plate1.human_barcode => 'on' } }
  let(:options) { { count: count, printable: printables, batch: batch } }

  before do
    batch.requests << request1
    batch.requests << request2
  end

  describe LabelPrinter::Label::BatchPlateDouble do
    context 'printing double labels' do
      let(:label_options) { { count: count, printable: printables, batch: batch } }
      let(:expected_count) { count.to_i * 2 }

      it_behaves_like 'a correct double label printer'
      it_behaves_like 'a correct multi-copy printer'
      it_behaves_like 'a correct filter'
    end
  end

  describe LabelPrinter::Label::BatchPlate do
    context 'returning single label class when selecting a 96 plate printer' do
      let(:label_options) { options.merge(printer_type_class: BarcodePrinterType) }
      let(:expected_count) { count.to_i }

      it_behaves_like 'a correct single label printer'
      it_behaves_like 'a correct multi-copy printer'
      it_behaves_like 'a correct filter'
    end
  end

  describe LabelPrinter::Label::BatchRedirect do
    context 'returning double label class when selecting a 384 well printer' do
      let(:label_options) { options.merge(printer_type_class: BarcodePrinterType384DoublePlate) }

      it_behaves_like 'a correct double label printer'
    end
  end
end
