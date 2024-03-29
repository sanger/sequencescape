# frozen_string_literal: true

FactoryBot.define do
  factory :accession_tag_list, class: 'Accession::TagList' do
    tags { build_list(:accession_tag, 5).index_by(&:name) }

    initialize_with { new(tags) }

    factory :standard_accession_tag_list do
      tags do
        [
          build(:sample_taxon_id_accession_tag),
          build(:sample_common_name_accession_tag),
          build(:country_of_origin_accession_tag),
          build(:collection_date_accession_tag),
          build(:gender_accession_tag),
          build(:phenotype_accession_tag),
          build(:donor_id_accession_tag),
          build(:sample_public_name_accession_tag),
          build(:disease_state_accession_tag),
          build(:rnai_accession_tag)
        ].index_by(&:name)
      end
    end

    skip_create
  end
end
