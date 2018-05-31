# frozen_string_literal: true

FactoryBot.define do
  factory :transfer_request do
    association(:asset, factory: :well)
    association(:target_asset, factory: :well)
  end
end
