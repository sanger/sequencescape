# frozen_string_literal: true

FactoryBot.define do
  factory :custom_metadatum_collection do
    asset factory: %i[labware]
    user

    factory :custom_metadatum_collection_with_metadata do
      transient { metadatum_count { 5 } }

      after(:create) do |custom_metadatum_collection, evaluator|
        create_list(
          :custom_metadatum,
          evaluator.metadatum_count,
          custom_metadatum_collection: custom_metadatum_collection
        )
      end
    end
  end
end
