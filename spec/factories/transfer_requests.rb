# frozen_string_literal: true

FactoryGirl.define do
  factory :transfer_request do
    association(:asset, factory: :well)
    association(:target_asset, factory: :well)
  end
end
