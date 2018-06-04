# frozen_string_literal: true

FactoryBot.define do
  factory :request_event do
    request
    event_name 'state_changed'
    from_state 'first_state'
    to_state 'second_state'
    current_from Time.zone.local(2008, 9, 1, 12, 0, 0)
  end
end
