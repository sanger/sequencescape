FactoryGirl.define do
  factory :container_json, class: Hash do
    skip_create

    sequence(:barcode) {|i| "AKER-{i}" }

    initialize_with { attributes.stringify_keys }
  end
end