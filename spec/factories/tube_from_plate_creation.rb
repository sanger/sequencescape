# frozen_string_literal: true

FactoryBot.define do
  factory :tube_from_plate_creation do
    child_purpose { |target| target.association(:tube_purpose) }
    parent { |target| target.association(:plate) } # Modify the prefix to avoid clashes with created tubes.
    user { |target| target.association(:user) }
  end
end
