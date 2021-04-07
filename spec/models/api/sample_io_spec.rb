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
             phenotype: 'positive',
             gc_content: 'Neutral',
             dna_source: 'Genomic',
             volume: 'N/A',
             sibling: '209_210',
             is_resubmitted: true,
             date_of_sample_collection: '02-Oct',
             date_of_sample_extraction: '02-Oct',
             sample_extraction_method: '5',
             sample_purified: 'N',
             purification_method: 'Other',
             concentration: '100',
             concentration_determined_by: 'Nanodrop',
             sample_type: 'MDA',
             sample_storage_conditions: '+4C',
             genotype: 'WT',
             age: '10 weeks',
             cell_type: 'iPSC-derived microglia',
             disease_state: 'Healthy',
             compound: 'lomitapide',
             dose: '10 uM',
             immunoprecipitate: 'antiKdm1a, ab17721, 4ug/IP',
             growth_condition: 'Oxford N2 media without geltrex',
             organism_part: 'Primary T cells',
             time_point: '2020-03-18',
             disease: 'Tumour Growing',
             subject: '19',
             treatment: '10uM lomitapide in 0.1% ethanol',
             date_of_consent_withdrawn: DateTime.new(2021, 3, 19, 13, 36, 51),
             user_id_of_consent_withdrawn: user.id
           }
  end

  let(:user) { create :user }

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'id' => subject.id,
      'name' => 'sample_testing_messages',
      'replicate' => nil,
      'organism' => nil,
      'strain' => nil,
      'ethnicity' => nil,
      'mother' => nil,
      'public_name' => nil,
      'accession_number' => nil,
      'common_name' => nil,
      'taxon_id' => nil,
      'country_of_origin' => nil,
      'gender' => nil,
      'sample_visibility' => nil,
      'geographical_region' => nil,
      'description' => nil,
      'father' => nil,
      'cohort' => nil,
      'sanger_sample_id' => subject.sanger_sample_id,
      'control' => nil,
      'empty_supplier_sample_name' => false,
      'supplier_name' => 'A name',
      'updated_by_manifest' => true,
      'phenotype' => 'positive',
      'gc_content' => 'Neutral',
      'dna_source' => 'Genomic',
      'customer_measured_volume' => 'N/A',
      'sibling' => '209_210',
      'is_resubmitted' => true,
      'date_of_sample_collection' => '02-Oct',
      'date_of_sample_extraction' => '02-Oct',
      'extraction_method' => '5',
      'purified' => 'N',
      'purification_method' => 'Other',
      'customer_measured_concentration' => '100',
      'concentration_determined_by' => 'Nanodrop',
      'sample_type' => 'MDA',
      'storage_conditions' => '+4C',
      'genotype' => 'WT',
      'age' => '10 weeks',
      'cell_type' => 'iPSC-derived microglia',
      'disease_state' => 'Healthy',
      'compound' => 'lomitapide',
      'dose' => '10 uM',
      'immunoprecipitate' => 'antiKdm1a, ab17721, 4ug/IP',
      'growth_condition' => 'Oxford N2 media without geltrex',
      'organism_part' => 'Primary T cells',
      'time_point' => '2020-03-18',
      'disease' => 'Tumour Growing',
      'subject' => '19',
      'treatment' => '10uM lomitapide in 0.1% ethanol',
      'date_of_consent_withdrawn' => '2021-03-19 13:36:51',
      'marked_as_consent_withdrawn_by' => user.login
    }
  end

  it_behaves_like('an IO object')
end
