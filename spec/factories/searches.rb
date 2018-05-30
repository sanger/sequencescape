# frozen_string_literal: true

FactoryBot.define do
  factory :search do
    sequence(:name) { |n| "Search #{n}" }
  end
end
