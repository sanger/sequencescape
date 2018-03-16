# frozen_string_literal: true

FactoryGirl.define do
  factory :reference_genome do
    sequence(:name) { |n| "ReferenceGenome#{n}" }
  end
end
