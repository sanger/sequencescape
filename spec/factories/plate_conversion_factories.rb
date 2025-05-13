# frozen_string_literal: true

FactoryBot.define do
  factory :plate_conversion do
    parent factory: %i[plate]
    purpose factory: %i[plate_purpose]
    target factory: %i[plate]
    user factory: %i[user]
  end
end
