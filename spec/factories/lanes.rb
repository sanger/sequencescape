# frozen_string_literal: true

FactoryBot.define do
  factory :lane, traits: [:with_sample_builder] do
    name { generate(:asset_name) }
    external_release { nil }
    factory(:empty_lane)

    factory :lane_with_stock_plate do
      after(:create) do |lane|
        lane.labware.ancestors << create(:plate, plate_purpose: PlatePurpose.stock_plate_purpose)
      end
    end
  end
end
