# frozen_string_literal: true

FactoryBot.define do
  factory :sample_manifest_asset do
    sanger_sample_id
    sample_manifest
    # asset factory: %i[receptacle]
    asset { create(:receptacle) }

    after(:build) do |sma|
      sma.sample_manifest.labware = [sma.asset.labware] if sma.sample_manifest &&
        sma.sample_manifest.core_behaviour.respond_to?(:labware=) && sma.asset
    end
  end
end
