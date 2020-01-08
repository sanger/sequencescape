# frozen_string_literal: true

FactoryBot.define do
  factory :broadcast_event_asset_audit, class: 'BroadcastEvent::AssetAudit' do
    association(:seed, factory: :asset_audit)
  end
end
