# frozen_string_literal: true

FactoryBot.define do
  factory :tube_rack do
    size { 96 }

    purpose factory: %i[tube_rack_purpose]

    transient { barcode { create(:barcode) } }

    after(:create) { |rack, evaluator| rack.barcodes << evaluator.barcode }

    factory :tube_rack_with_tubes do
      transient { locations { %w[A1 H12] } }

      after(:build) do |rack, generator|
        generator.locations.each { |location| create(:sample_tube, :in_a_rack, tube_rack: rack, coordinate: location) }
      end
    end
  end
end
