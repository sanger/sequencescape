# frozen_string_literal: true

FactoryGirl.define do
  factory :search do
    sequence(:name) { |n| "Search #{n}" }
  end
end
