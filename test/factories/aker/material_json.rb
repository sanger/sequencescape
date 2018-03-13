# frozen_string_literal: true

FactoryGirl.define do
  factory :material_json, class: Hash do
    skip_create

    transient do
      container_has_an_address false
    end

    sequence(:_id) { |n| "#{SecureRandom.uuid}#{n}" }
    gender 'male'
    donor_id 'd'
    phenotype 'p'
    common_name 'Mouse'

    initialize_with { attributes.stringify_keys }

    after(:build) do |material, evaluator|
      container_type = evaluator.container_has_an_address ? :container_with_address : :container
      material['container'] = attributes_for(container_type)
    end
  end
end
