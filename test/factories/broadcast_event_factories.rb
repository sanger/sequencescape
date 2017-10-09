FactoryGirl.define do
  factory :broadcast_event_asset_audit, class: BroadcastEvent::AssetAudit do
    association(:seed, factory: :asset_audit)
  end
end
