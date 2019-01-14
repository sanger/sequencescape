# frozen_string_literal: true

require 'rails_helper'

describe LabelPrinter::Label::SampleManifestPlateDouble do
  let(:sample_manifest) { create :sample_manifest_with_samples }
  let(:label_options) { { sample_manifest: sample_manifest, only_first_label: only_first_label } }
  let(:sample_manifest_plates) { sample_manifest.printables }

  subject { described_class.new(label_options) }

  context 'printing only the first label' do
    let(:only_first_label) { true }

    it 'should produce the correct label' do
      plate = sample_manifest_plates.first
      expected_label = {
        labels: {
          body: [{
            main_label: {
              left_text: plate.human_barcode,
              right_text: "#{sample_manifest.study.abbreviation} #{plate.barcode_number}",
              barcode: plate.ean13_barcode
            }
          },
                 {
                   extra_label: {
                     left_text: Time.zone.today.strftime('%e-%^b-%Y'),
                     right_text: sample_manifest.purpose.name
                   }
                 }]
        }
      }
      expect(subject.to_h).to eq(expected_label)
    end
  end

  context 'printing all labels' do
    let(:only_first_label) { false }

    it 'should have the correct plates' do
      expect(subject.assets).to eq(sample_manifest_plates)
    end
  end
end
