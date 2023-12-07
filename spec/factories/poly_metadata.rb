# frozen_string_literal: true

FactoryBot.define do
  factory :poly_metadatum do
    sequence(:key) { |n| "some_key_#{n}" }
    sequence(:value) { |n| "some_value_#{n}" }
    metadatable factory: %i[request]
  end
end
