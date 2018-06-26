# frozen_string_literal: true

FactoryBot.define do
  factory :custom_metadatum do
    sequence(:key) { |n| "Key #{n}" }
    value 'a bit of metadata'
    custom_metadatum_collection
  end
end
