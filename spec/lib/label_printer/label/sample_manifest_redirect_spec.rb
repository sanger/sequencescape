# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabelPrinter::Label::SampleManifestRedirect do
  subject(:labels) do
    described_class.new(
      sample_manifest: manifest,
      printer_type_class: BarcodePrinterType1DTube,
      only_first_label: false
    ).labels
  end

  context 'with a compound sample tube manifest' do
    let(:manifest) do
      create(
        :sample_manifest,
        asset_type: 'compound_tube',
        count: 2,
        purpose: Tube::Purpose.standard_sample_tube
      )
    end
    let(:tubes) { manifest.labware }

    before do
      handler = SequencescapeExcel::SpecialisedField::ComponentTagSequence
      create(:tag_group, name: handler::TAG_GROUP_NAME, tag_count: 3)
      manifest.generate
    end

    it 'prints one label per tube, not one per row' do
      expect(labels.size).to eq(tubes.size)
    end

    it 'prints the barcode of each tube' do
      expect(labels.pluck(:barcode))
        .to match_array(tubes.map(&:machine_barcode))
    end
  end
end
