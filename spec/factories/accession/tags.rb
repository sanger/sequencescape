# frozen_string_literal: true

FactoryBot.define do
  factory :accession_tag, class: 'Accession::Tag' do
    name { :tag_1 }
    groups { %i[group_1 group_2] }
    mandatory_services { %i[SERVICE_1 SERVICE_2] }
    ebi_name { :ebi_tag_1 }

    initialize_with { new(name:, groups:, mandatory_services:, ebi_name:) }
    skip_create

    factory :sample_taxon_id_accession_tag do
      name { :sample_taxon_id }
      mandatory_services { %i[ENA EGA] }
      groups { [:sample_name] }
      ebi_name { :taxon_id }
    end

    factory :country_of_origin_accession_tag, class: '::Accession::TagCountryOfOrigin' do
      class_name { '::Accession::TagCountryOfOrigin' }
      name { :country_of_origin }
      mandatory_services { %i[ENA EGA] }
      groups { [:sample_attributes] }
      ebi_name { :'geographic_location_(country_and/or_sea)' }
    end

    factory :collection_date_accession_tag, class: '::Accession::TagCollectionDate' do
      class_name { '::Accession::TagCollectionDate' }
      name { :date_of_sample_collection }
      mandatory_services { %i[ENA EGA] }
      groups { [:sample_attributes] }
      ebi_name { :collection_date }
    end

    factory :sample_common_name_accession_tag do
      name { :sample_common_name }
      mandatory_services { %i[ENA EGA] }
      groups { [:sample_name] }
      ebi_name { :common_name }
    end

    factory :gender_accession_tag do
      name { :gender }
      mandatory_services { [:EGA] }
      groups { %i[sample_attributes array_express] }
      ebi_name { nil }
    end

    factory :phenotype_accession_tag do
      name { :phenotype }
      mandatory_services { [:EGA] }
      groups { %i[sample_attributes array_express] }
      ebi_name { nil }
    end

    factory :donor_id_accession_tag do
      name { :donor_id }
      mandatory_services { [:EGA] }
      groups { %i[sample_attributes array_express] }
      ebi_name { :subject_id }
    end

    factory :sample_public_name_accession_tag do
      name { :sample_public_name }
      groups { [:array_express] }
      mandatory_services { [] }
      ebi_name { nil }
    end

    factory :disease_state_accession_tag do
      name { :disease_state }
      groups { [:array_express] }
      mandatory_services { [] }
      ebi_name { nil }
    end

    factory :rnai_accession_tag do
      name { :rnai }
      groups { [:array_express] }
      mandatory_services { [] }
      ebi_name { nil }
    end
  end
end
