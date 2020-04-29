# frozen_string_literal: true

FactoryBot.define do
  factory :tube_rack do
    size { 96 }
    transient do
      barcode { create(:barcode) }
    end
    after(:create) do |rack, evaluator|
      rack.barcodes << evaluator.barcode
    end

    factory :tube_rack_with_tubes do
      transient do
        locations { %w[A1 H12] }
      end

      after(:build) do |rack, generator|
        generator.locations.each do |location|
          create(:sample_tube, :in_a_rack, tube_rack: rack, coordinate: location)
        end
      end
    end
  end
end
