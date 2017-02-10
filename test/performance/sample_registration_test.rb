require 'test_helper'
require 'rails/performance_test_help'

class SampleRegistrationTest < ActionDispatch::PerformanceTest
  attr_reader :study

  def setup
    user = create :user
    post '/login', 'login' => user.login, 'password' => user.password
    @study = create :study
  end

  test 'sample registration' do
    post  study_sample_registration_index_path(study),
          'sample_registrars' => {
            '0' => {
              'ignore' => '0',
              'asset_group_name' => 'test3',
              'sample_attributes' => {
                'name' => 'test3',
                'sample_metadata_attributes' => {
                  'cohort' => 'test',
                  'gender' => 'Male',
                  'country_of_origin' => 'test',
                  'geographical_region' => 'test',
                  'ethnicity' => 'test',
                  'dna_source' => 'Genomic',
                  'volume' => '10',
                  'supplier_plate_id' => 'test',
                  'mother' => 'test',
                  'father' => 'test',
                  'replicate' => 'test',
                  'organism' => 'test',
                  'gc_content' => 'Neutral',
                  'sample_public_name' => 'test',
                  'sample_sra_hold' => 'Hold',
                  'sample_common_name' => 'test',
                  'sample_taxon_id' => '0',
                  'sample_strain_att' => 'test',
                  'sample_description' => 'test',
                  'sample_ebi_accession_number' => 'test',
                  'reference_genome_id' => '1',
                  'genotype' => 'test',
                  'phenotype' => 'test',
                  'age' => '',
                  'developmental_stage' => 'test',
                  'cell_type' => 'test',
                  'disease_state' => 'test',
                  'compound' => 'test',
                  'dose' => '',
                  'immunoprecipitate' => 'test',
                  'growth_condition' => 'test',
                  'rnai' => 'test',
                  'organism_part' => 'test',
                  'time_point' => 'test',
                  'subject' => 'test',
                  'disease' => 'test',
                  'treatment' => 'test',
                  'donor_id' => 'test'
                }
              },
              'sample_tube_attributes' => {
                'two_dimensional_barcode' => 'test'
              }
            }
          },
          'study_id' => study.id
  end
end
