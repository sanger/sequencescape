require 'rails_helper'

RSpec.describe Api::Messages::PacBioRunIO, type: :model do
  subject { Api::Messages::PacBioRunIO.to_hash(pac_bio_batch) }

  let(:plate) { create(:plate_with_tagged_wells, sample_count: 2) }

  let(:aliquot_1) { create :tagged_aliquot }
  let(:aliquot_2) { create :untagged_aliquot }

  let(:library_tube_1) { create :pac_bio_library_tube, aliquot: aliquot_1 }
  let(:library_tube_2) { create :pac_bio_library_tube, aliquot: aliquot_2 }

  let(:pac_bio_batch) do
    batch = create :pac_bio_sequencing_batch, assets: [library_tube_1, library_tube_2], target_plate: plate
    batch.reload
    batch
  end

  let(:well_a1) { plate.wells.located_at('A1').first }
  let(:well_b1) { plate.wells.located_at('B1').first }

  let(:expected_json) {
    {
      'pac_bio_run_id' => pac_bio_batch.id,
      'pac_bio_run_uuid' => pac_bio_batch.uuid,
      'plate_barcode' => plate.sanger_human_barcode,
      'plate_uuid_lims' => plate.uuid,
      'wells' => [
        {
          'well_label' => 'A1',
          'well_uuid_lims' => well_a1.uuid,
          'samples' => [{
            'pac_bio_library_tube_id_lims' => library_tube_1.sanger_human_barcode,
            'pac_bio_library_tube_uuid' => library_tube_1.uuid,
            'pac_bio_library_tube_name' => library_tube_1.name,
            'pac_bio_library_tube_legacy_id' => library_tube_1.id,
            'sample_uuid' => aliquot_1.sample.uuid,
            'tag_sequence' => aliquot_1.tag.oligo,
            'tag_set_id_lims' => aliquot_1.tag.tag_group_id,
            'tag_identifier' => aliquot_1.tag.map_id,
            'tag_set_name' => aliquot_1.tag.tag_group.name
          }]
        }, {
          'well_label' => 'B1',
          'well_uuid_lims' => well_b1.uuid,
          'samples' => [{
            'pac_bio_library_tube_id_lims' => library_tube_2.sanger_human_barcode,
            'pac_bio_library_tube_uuid' => library_tube_2.uuid,
            'pac_bio_library_tube_name' => library_tube_2.name,
            'pac_bio_library_tube_legacy_id' => library_tube_2.id,
            'sample_uuid' => aliquot_2.sample.uuid
          }]
        }
      ]
    }
  }

  it 'generates valid json' do
    actual = subject.as_json
    actual.delete('updated_at')
    expect(actual).to eq(expected_json)
  end
end
