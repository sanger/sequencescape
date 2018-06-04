# frozen_string_literal: true

FactoryBot.define do
  factory :program do
    sequence(:name) { |n| "Program#{n}" }
  end
end
