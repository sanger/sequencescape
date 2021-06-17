# frozen_string_literal: true

FactoryBot.define do
  factory :sample_manifest_asset do
    sanger_sample_id
    sample_manifest
    association(:asset, factory: :receptacle)

    after(:build) { |sma| sma.sample_manifest.labware = [sma.asset.labware] if sma.sample_manifest && sma.asset }
  end
end
