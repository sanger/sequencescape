# frozen_string_literal: true

FactoryBot.define do
  trait :plate_exists_in_sequencescape do
    transient do
      sequence(:index) { |n| n }
    end

    barcode { "AKER-#{index}" }

    before(:create) do |container|
      plate = build(:plate)
      plate.aker_barcode = container.barcode
      plate.save
    end
  end

  trait :with_address_for_aker do
    transient do
      sequence(:address_for_aker) do |value|
        quotient, remainder = value.divmod(12)
        "#{('A'..'Z').to_a[quotient % 8]}:#{(remainder % 12) + 1}"
      end
    end
    address { address_for_aker }
  end

  factory :container, class: 'Aker::Container', traits: [:plate_exists_in_sequencescape]

  factory :container_with_address, class: 'Aker::Container', traits: %i[
    plate_exists_in_sequencescape
    with_address_for_aker
  ]
end
