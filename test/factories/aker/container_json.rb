# frozen_string_literal: true

FactoryBot.define do
  factory :container_json, class: Hash do
    skip_create
    address { 'A:1' }
    sequence(:barcode) { |i| "AKER-#{i}" }

    initialize_with { attributes.stringify_keys }
  end
end
