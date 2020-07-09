# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::SampleIO, type: :model do
  subject do
    create :sample,
           name: 'sample_testing_messages',
           empty_supplier_sample_name: false,
           updated_by_manifest: true,
           sample_metadata_attributes: {
             supplier_name: 'A name',
             phenotype: 'positive'
           }
  end

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id,
      'name' => 'sample_testing_messages',
      'replicate' => nil,
      'organism' => nil,
      'sample_strain_att' => nil,
      'ethnicity' => nil,
      'mother' => nil,
      'sample_public_name' => nil,
      'sample_ebi_accession_number' => nil,
      'sample_common_name' => nil,
      'sample_taxon_id' => nil,
      'country_of_origin' => nil,
      'gender' => nil,
      'sample_sra_hold' => nil,
      'geographical_region' => nil,
      'sample_description' => nil,
      'father' => nil,
      'cohort' => nil,
      'sanger_sample_id' => subject.sanger_sample_id,
      'control' => nil,
      'empty_supplier_sample_name' => false,
      'supplier_name' => 'A name',
      'updated_by_manifest' => true,
      'phenotype' => 'positive'
    }
  end

  it_behaves_like('an IO object')
end
