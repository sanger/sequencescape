# frozen_string_literal: true

FactoryBot.define do
  factory :asset_audit do
    sequence(:message) { |n| "Audit message #{n}" }
    sequence(:key) { |n| "instrument_process_key_#{n}" }
    created_by { 'abc123' }
    witnessed_by { 'jane' }
    asset factory: %i[labware]
  end
end
