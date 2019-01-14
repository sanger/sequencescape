# frozen_string_literal: true

require 'rails_helper'

shared_examples 'a correct single label printer' do
  it 'should produce the correct label' do
    expected_label = {
      labels: {
        body: [{
          main_label: {
            barcode: plate1.ean13_barcode,
            bottom_left: plate1.human_barcode,
            bottom_right: "#{batch.output_plate_role} #{batch.output_plate_purpose.name} #{plate1.barcode_number}",
            top_far_right: nil,
            top_left: date_today,
            top_right: batch.studies.first.abbreviation
          }
        }]
      }
    }
    expect(subject.to_h).to eq(expected_label)
  end
end

shared_examples 'a correct double label printer' do
  it 'should produce the correct label' do
    expected_label = {
      labels: {
        body: [{
          main_label: {
            left_text: plate1.human_barcode.to_s,
            right_text: plate1.barcode_number.to_s,
            barcode: plate1.ean13_barcode
          }
        },
        {
          extra_label: {
            left_text: date_today,
            right_text: "#{batch.output_plate_role} #{batch.output_plate_purpose.name} #{plate1.barcode_number} #{batch.studies.first.abbreviation}"
          }
        }]
      }
    }
    expect(subject.to_h).to eq(expected_label)
  end
end

shared_examples 'a correct multi-copy printer' do
  let(:count) { '3' }

  it 'prints multiple copies' do
    expect(subject.create_labels.count).to eq(expected_count)
  end
end

shared_examples 'a correct filter' do
  let(:printables) do
    { plate1.human_barcode => 'on',
      plate2.human_barcode => 'on' }
  end

  it 'should have the correct plates' do
    expect(subject.assets).to eq([plate1, plate2])
  end
end


context 'printing labels' do
  let(:count) { '1' }
  let(:date_today) { Time.zone.today.strftime('%e-%^b-%Y') }
  let(:batch) { create :batch }
  let(:study) { create :study }
  let(:request1) do
    order = create(:order,
                   order_role: OrderRole.new(role: 'test_role'),
                   study: study,
                   assets: [create(:empty_sample_tube)])
    create(:well_request,
           asset: create(:well_with_sample_and_plate),
           target_asset: create(:well_with_sample_and_plate),
           order: order)
  end
  let(:request2) do
    order = create(:order,
                   order_role: OrderRole.new(role: 'test_role'),
                   study: study,
                   assets: [create(:empty_sample_tube)])
    create(:well_request,
           asset: create(:well_with_sample_and_plate),
           target_asset: create(:well_with_sample_and_plate),
           order: order)
  end
  let(:plate1) { request1.target_asset.plate }
  let(:plate2) { request2.target_asset.plate }
  let(:printables) { { plate1.human_barcode => 'on' } }
  let(:options) { { count: count, printable: printables, batch: batch } }

  setup do
    batch.requests << request1
    batch.requests << request2
  end

  subject { described_class.new(label_options) }

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
