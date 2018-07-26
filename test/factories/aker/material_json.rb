# frozen_string_literal: true

FactoryBot.define do
  factory :material_json, class: Hash do
    skip_create

    sequence(:_id) { |n| "#{SecureRandom.uuid}" }
    gender 'male'
    donor_id 'd'
    sequence(:supplier_name) do |value|
      "supplier#{value}"
    end
    phenotype 'p'
    common_name 'Mouse'
    sequence(:address) do |value|
      quotient, remainder = value.divmod(12)
      "#{('A'..'Z').to_a[quotient % 8]}:#{(remainder % 12) + 1}"
    end

    initialize_with { attributes.stringify_keys }
  end
end
