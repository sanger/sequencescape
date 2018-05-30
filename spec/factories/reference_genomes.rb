# frozen_string_literal: true

FactoryBot.define do
  factory :reference_genome do
    sequence(:name) { |n| "ReferenceGenome#{n}" }
  end
end
