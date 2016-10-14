FactoryGirl.define do

  factory :process_metadatum do
    sequence(:key) { |n| "Key #{n}"}
    value "a bit of metadata"
    process_metadatum_collection
  end
end