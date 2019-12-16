# frozen_string_literal: true

FactoryBot.define do
  factory :billing_field, class: 'Billing::Field' do
    sequence(:order) { |n| n }
    name { "field_#{order}" }
    number_of_spaces { 15 }
    sequence(:position_from) { |n| n + 20 }
    position_to { (position_from.to_s.to_i + 15) }
    right_justified { false }

    skip_create
  end
end
