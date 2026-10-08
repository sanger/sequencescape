# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifest::CompoundTubeBehaviour, :sample_manifest do
  let(:study) { create(:study) }
  let(:tag_count) { 3 }
  let(:tag_group_name) do
    SequencescapeExcel::SpecialisedField::ComponentTagSequence::TAG_GROUP_NAME
  end
  let(:manifest) do
    create(
      :sample_manifest,
      study: study,
      asset_type: 'compound_tube',
      count: 2,
      purpose: Tube::Purpose.standard_sample_tube
    )
  end
  let(:tubes) { manifest.labware }

  it 'does not put the samples in receptacles' do
    expect(manifest.core_behaviour).not_to be_samples_in_receptacles
  end

  context 'when the component tag group exists' do
    before do
      create(:tag_group, name: tag_group_name, tag_count: tag_count)
      manifest.generate
    end

    it 'creates a tube for each tube requested' do
      expect(tubes.size).to eq(2)
    end

    it 'creates sample tubes' do
      expect(tubes).to all(be_a(SampleTube))
    end

    it 'creates a row for each tag in the tag group in each tube' do
      rows = manifest.sample_manifest_assets.group_by(&:asset)
      expect(rows.transform_values(&:size))
        .to eq(tubes.to_h { |tube| [tube.receptacle, tag_count] })
    end

    it 'gives each row its own sanger sample id' do
      ids = manifest.sample_manifest_assets.map(&:sanger_sample_id)
      expect(ids.uniq.size).to eq(2 * tag_count)
    end

    it 'lists each tube barcode once on the manifest' do
      expect(manifest.barcodes).to match_array(tubes.map(&:human_barcode))
    end

    it 'shows the tube barcode on each of its rows' do
      barcodes = manifest.details_array.pluck(:barcode)
      expect(barcodes.tally)
        .to eq(tubes.to_h { |tube| [tube.human_barcode, tag_count] })
    end

    it 'prints one label per tube' do
      expect(manifest.printables).to match_array(tubes)
    end
  end

  context 'when the component tag group does not exist' do
    it 'does not generate the manifest' do
      expect { manifest.generate }
        .to raise_error(ActiveRecord::RecordNotFound, /#{tag_group_name}/)
    end
  end
end
