# frozen_string_literal: true

FactoryGirl.define do
  factory :api_application do
    sequence(:name) { |i| "App #{i}" }
    contact 'test@example.com'
    privilege 'full'
  end
end
