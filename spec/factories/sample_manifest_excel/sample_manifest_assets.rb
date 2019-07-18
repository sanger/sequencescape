# frozen_string_literal: true

FactoryBot.define do
  factory :sample_manifest_asset do
    sanger_sample_id
    sample_manifest
    association(:asset, factory: :receptacle)
  end
end
