# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    description { 'It is okay I guess' }
    association(:commentable, factory: :labware)
  end
end
