# frozen_string_literal: true

FactoryBot.define do
  factory :poly_metadatum do
    metadatable factory: %i[request]
    sequence(:key) { |n| "some_key_#{n}" }
    sequence(:value) { |n| "some_value_#{n}" }
  end
end
