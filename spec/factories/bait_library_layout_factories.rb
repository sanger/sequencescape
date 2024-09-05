# frozen_string_literal: true

FactoryBot.define do
  factory :bait_library_layout do
    user
    plate
    layout { nil } # This is generated after creation.
  end
end
