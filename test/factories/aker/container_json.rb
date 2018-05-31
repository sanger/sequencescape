# frozen_string_literal: true

FactoryGirl.define do
  factory :container_json, class: Hash do
    skip_create
    address { 'A:1' }
    sequence(:barcode) { |_i| "AKER-#{_i}" }

    initialize_with { attributes.stringify_keys }
  end
end
