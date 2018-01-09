# frozen_string_literal: true

FactoryGirl.define do
  factory :lane, traits: [:with_sample_builder] do
    name { generate :asset_name }
    external_release nil
    factory(:empty_lane)
  end
end
