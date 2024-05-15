# frozen_string_literal: true
FactoryBot.define do
  factory :custom_metadatum_collection_with_asset,  parent: :custom_metadatum_collection do
    user

    transient do
      asset { create(:labware) }
    end

    after(:build) do |custom_metadatum_collection, evaluator|
      custom_metadatum_collection.asset = evaluator.asset
    end

    factory :custom_metadatum_collection_with_metadata_with_asset do
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