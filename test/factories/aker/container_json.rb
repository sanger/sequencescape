# frozen_string_literal: true

FactoryGirl.define do
  factory :container_json, class: Hash do
    skip_create

    sequence(:barcode) { |_i| 'AKER-{i}' }

    initialize_with { attributes.stringify_keys }
  end
end
