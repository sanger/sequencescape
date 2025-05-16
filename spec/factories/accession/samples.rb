# frozen_string_literal: true

FactoryBot.define do
  factory :sample_metadata_for_accessioning, class: 'Sample::Metadata' do
    sample_taxon_id { 1 }
    sample_common_name { 'A common name' }
    donor_id { '1' }
    gender { 'Unknown' }
    phenotype { 'Indescribeable' }
    growth_condition { 'No' }
    sample_public_name { 'Sample 666' }
    disease_state { 'Awful' }
    country_of_origin { 'Australia' }
    date_of_sample_collection { '2000-01-01T00:00' }

    factory :sample_metadata_with_accession_number do
      sample_ebi_accession_number { 'EBI1234' }
    end
  end

  factory :minimal_sample_metadata_for_accessioning, class: 'Sample::Metadata' do
    sample_taxon_id { 1 }
    sample_common_name { 'A common name' }
  end

  factory :sample_for_accessioning, parent: :sample do
    sample_metadata { create(:sample_metadata_for_accessioning) }

    trait :skip_accessioning do
      # Accessioning is triggered on sample saving, unless processing_manifest is true
      before(:create) { Sample::Current.processing_manifest = true }
    end

    factory :sample_for_accessioning_with_open_study do
      studies { [create(:open_study, accession_number: 'ENA123')] }
    end

    factory :sample_for_accessioning_with_managed_study do
      studies { [create(:managed_study, accession_number: 'ENA123')] }
    end
  end

  factory :accession_sample, class: 'Accession::Sample' do
    standard_tags { build(:standard_accession_tag_list) }
    sample { create(:sample_for_accessioning_with_open_study) }

    initialize_with { new(standard_tags, sample) }

    factory :invalid_accession_sample do
      sample do
        create(
          :sample_for_accessioning_with_open_study,
          sample_metadata: create(:sample_metadata_with_accession_number)
        )
      end
    end

    skip_create
  end
end
