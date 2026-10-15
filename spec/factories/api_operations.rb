# frozen_string_literal: true

FactoryBot.define do
  factory :api_operation do
    api_application
    sequence(:external_id) { |i| "request-#{i}" }
    operation_type { 'reception_and_work_order' }
    payload { '{}' }
    payload_digest { Digest::SHA256.hexdigest(payload) }
  end
end
