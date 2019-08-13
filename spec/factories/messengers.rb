# frozen_string_literal: true

FactoryBot.define do
  factory :messenger_creator do
    root { 'a_plate' }
    template { 'FluidigmPlateIO' }
    purpose { |purpose| purpose.association(:plate_purpose) }
  end

  factory :messenger do
    root { 'barcode' }
    association(:target, factory: :barcode)
    template { 'BarcodeIO' }
  end
end
