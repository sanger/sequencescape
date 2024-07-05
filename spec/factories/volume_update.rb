# frozen_string_literal: true

FactoryBot.define do
  factory :volume_update do
    sequence(:volume_change, &:to_f)
    created_by { 'abc123' }
    target factory: %i[labware]
  end
end
