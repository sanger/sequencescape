FactoryGirl.define do


  factory :process_metadatum_collection do
    asset
    user

    factory :process_metadatum_collection_with_metadata do
      transient do
        metadatum_count 5
      end

      after(:create) do |process_metadatum_collection, evaluator|
        create_list(:process_metadatum, evaluator.metadatum_count, process_metadatum_collection: process_metadatum_collection)
      end
    end
  end
end