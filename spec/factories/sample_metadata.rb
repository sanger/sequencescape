# frozen_string_literal: true

FactoryBot.define do
  factory :sample_metadata, class: 'Sample::Metadata' do
    reference_genome_id { FactoryBot.create(:reference_genome).id }
    factory :sample_metadata_with_gender do
      gender { :male }
    end

    factory :sample_metadata_for_api do
      organism { 'organism' }
      cohort { 'cohort' }
      country_of_origin { 'country_of_origin' }
      geographical_region { 'geographical_region' }
      ethnicity { 'ethnicity' }
      volume { 'volume' }
      mother { 'mother' }
      father { 'father' }
      replicate { 'replicate' }
      sample_public_name { 'sample_public_name' }
      sample_common_name { 'sample_common_name' }
      sample_description { 'sample_description' }
      sample_strain_att { 'sample_strain_att' }
      sample_ebi_accession_number { 'sample_ebi_accession_number' }
      sibling { 'sibling' }
      date_of_sample_collection { 'date_of_sample_collection' }
      date_of_sample_extraction { 'date_of_sample_extraction' }
      sample_extraction_method { 'sample_extraction_method' }
      sample_purified { 'sample_purified' }
      purification_method { 'purification_method' }
      concentration { 'concentration' }
      concentration_determined_by { 'concentration_determined_by' }
      sample_type { 'sample_type' }
      sample_storage_conditions { 'sample_storage_conditions' }
      supplier_name { 'supplier_name' }
      genotype { 'genotype' }
      phenotype { 'phenotype' }
      developmental_stage { 'developmental_stage' }
      cell_type { 'cell_type' }
      disease_state { 'disease_state' }
      compound { 'compound' }
      immunoprecipitate { 'immunoprecipitate' }
      growth_condition { 'growth_condition' }
      rnai { 'rnai' }
      organism_part { 'organism_part' }
      time_point { 'time_point' }
      disease { 'disease' }
      subject { 'subject' }
      collected_by { 'collected_by' }

      consent_withdrawn { false }

      treatment { 'treatment' }
    end
  end
end
