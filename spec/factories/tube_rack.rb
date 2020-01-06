# frozen_string_literal: true

FactoryBot.define do
  factory :tube_rack do
    transient do
      barcode { create(:barcode) }
    end
    after(:create) do |rack, evaluator|
      rack.barcodes << evaluator.barcode
    end
  end
end
