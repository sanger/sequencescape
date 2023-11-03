# frozen_string_literal: true

FactoryBot.define do
  factory :broadcast_event_asset_audit, class: 'BroadcastEvent::AssetAudit' do
    seed factory: %i[asset_audit]
  end

  factory :event_subject, class: Hash do
    skip_create
    role_type { 'a_role_type' }
    subject_type { 'a_subject_type' }
    friendly_name { 'a_friendly_name' }
    uuid { SecureRandom.uuid }
    initialize_with { attributes }
  end
end
