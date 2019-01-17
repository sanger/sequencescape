# frozen_string_literal: true

FactoryBot.define do
  factory :product_line do
    sequence(:name) { |n| "ProductLine#{n}" }
  end
end
