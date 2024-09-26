# frozen_string_literal: true

FactoryBot.define do
  factory :transfer_request_collection do
    transient do
      target_tube_count { 1 }
      target_assets do
        Array.new(target_tube_count) { create(:receptacle, labware: create(:stock_multiplexed_library_tube)) }
      end

      transfer_request_count { 5 }
    end

    transfer_requests do
      Array.new(transfer_request_count) { create(:transfer_request, target_asset: target_assets.sample) }
    end
    user { create :user }
  end
end
