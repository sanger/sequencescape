# frozen_string_literal: true

require 'rails_helper'

describe LabelPrinter::Label::SampleManifestPlateDouble, :sample_manifest do
  subject { described_class.new(label_options) }

  let(:sample_manifest) { create :pending_plate_sample_manifest }
  let(:label_options) { { sample_manifest:, only_first_label: } }
  let(:sample_manifest_plates) { sample_manifest.printables }

  context 'printing only the first label' do
    let(:only_first_label) { true }

    it 'produces the correct label' do
      plate = sample_manifest_plates.first
      expected_labels = [
        {
          left_text: plate.human_barcode,
          right_text: "#{sample_manifest.study.abbreviation} #{plate.barcode_number}",
          barcode: plate.machine_barcode,
          label_name: 'main_label'
        },
        {
          left_text: Time.zone.today.strftime('%e-%^b-%Y'),
          right_text: sample_manifest.purpose.name,
          label_name: 'extra_label'
        }
      ]
      expect(subject.labels).to eq(expected_labels)
    end
  end

  context 'printing all labels' do
    let(:only_first_label) { false }

    it 'has the correct plates' do
      expect(subject.assets).to eq(sample_manifest_plates)
    end
  end
end
