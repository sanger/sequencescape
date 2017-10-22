FactoryGirl.define do
  factory :accession_tag, class: Accession::Tag do
    name      :tag_1
    groups    [:group_1, :group_2]
    services  [:SERVICE_1, :SERVICE_2]
    ebi_name   :ebi_tag_1

    initialize_with { new(name: name, groups: groups, services: services, ebi_name: ebi_name) }
    skip_create

    factory :sample_taxon_id_accession_tag do
      name      :sample_taxon_id
      services  [:ENA, :EGA]
      groups    [:sample_name]
      ebi_name  :taxon_id
    end

    factory :sample_common_name_accession_tag do
      name      :sample_common_name
      services  [:ENA, :EGA]
      groups    [:sample_name]
      ebi_name  :common_name
    end

    factory :gender_accession_tag do
      name      :gender
      services  [:EGA]
      groups    [:sample_attributes, :array_express]
      ebi_name  nil
    end

    factory :phenotype_accession_tag do
      name      :phenotype
      services  [:EGA]
      groups    [:sample_attributes, :array_express]
      ebi_name  nil
    end

    factory :donor_id_accession_tag do
      name      :donor_id
      services  [:EGA]
      groups    [:sample_attributes, :array_express]
      ebi_name  :subject_id
    end

    factory :sample_public_name_accession_tag do
      name      :sample_public_name
      groups    [:array_express]
      services  []
      ebi_name  nil
    end

    factory :disease_state_accession_tag do
      name      :disease_state
      groups    [:array_express]
      services  []
      ebi_name  nil
    end

    factory :rnai_accession_tag do
      name      :rnai
      groups    [:array_express]
      services  []
      ebi_name  nil
    end
  end
end
