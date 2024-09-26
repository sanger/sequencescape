# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::AliquotIO do
  subject do
    create(:aliquot,
           receptacle: well,
           sample:,
           study:,
           project:,
           library: well,
           tag:,
           insert_size_from: 100,
           insert_size_to: 200,
           bait_library:)
  end

  let(:well) { create(:empty_well) }
  let(:sample) { create(:sample) }
  let(:study) { create(:study) }
  let(:project) { create(:project) }
  let(:tag) { create(:tag) }
  let(:bait_library) { create(:bait_library) }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'created_at' => subject.created_at.to_s,
      'updated_at' => subject.updated_at.to_s,
      'receptacle_uuid' => well.uuid,
      'receptacle_internal_id' => well.id,
      'library_uuid' => well.uuid,
      'library_internal_id' => well.id,
      'receptacle_type' => 'well',
      'sample_uuid' => sample.uuid,
      'sample_internal_id' => sample.id,
      'study_uuid' => study.uuid,
      'study_internal_id' => study.id,
      'project_uuid' => project.uuid,
      'project_internal_id' => project.id,
      'library_type' => subject.library_type,
      'tag_uuid' => tag.uuid,
      'tag_internal_id' => tag.id,
      'id' => subject.id,
      'insert_size_from' => 100,
      'insert_size_to' => 200,
      'bait_library_name' => bait_library.name,
      'bait_library_target_species' => bait_library.target_species,
      'bait_library_supplier_identifier' => bait_library.supplier_identifier,
      'bait_library_supplier_name' => bait_library.bait_library_supplier.name
    }
  end

  it_behaves_like('an IO object')

  context 'with minimal data' do
    subject { create(:minimal_aliquot) }

    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'created_at' => subject.created_at.to_s,
        'updated_at' => subject.updated_at.to_s,
        'receptacle_uuid' => subject.receptacle.uuid,
        'receptacle_internal_id' => subject.receptacle_id,
        'receptacle_type' => 'receptacle',
        'sample_uuid' => subject.sample.uuid,
        'sample_internal_id' => subject.sample.id,
        'id' => subject.id
      }
    end

    it_behaves_like('an IO object')
  end
end
