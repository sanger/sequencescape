# frozen_string_literal: true

FactoryBot.define do
  factory :asset_group do
    name { |_a| generate :asset_group_name }
    study

    transient do
      asset_type :untagged_well
      asset_count 0
    end

    assets do
      Array.new(asset_count) { create asset_type }
    end
  end

  factory :asset_group_asset do
    association(:asset, factory: :receptacle)
    asset_group
  end
end
