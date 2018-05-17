# frozen_string_literal: true

FactoryGirl.define do
  factory :material_json, class: Hash do
    skip_create

    sequence(:_id) { |n| "#{SecureRandom.uuid}#{n}" }
    gender 'male'
    donor_id 'd'
    phenotype 'p'
    common_name 'Mouse'
    sequence(:address) { |n| "A:#{n}" }

    initialize_with { attributes.stringify_keys }
  end
end
