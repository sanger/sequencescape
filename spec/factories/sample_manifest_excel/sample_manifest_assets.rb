# frozen_string_literal: true

FactoryBot.define do
  factory :sample_manifest_asset do
    sanger_sample_id
    sample_manifest
    association(:asset, factory: :receptacle)

    after(:build) do |sample_manifest_asset|
      sample_manifest_asset.sample_manifest.labware = [sample_manifest_asset.asset.labware] if sample_manifest_asset
        .sample_manifest
    end
  end
end
