# frozen_string_literal: true
FactoryBot.define do
  factory :aliquot_index do
    aliquot
    lane
    sequence(:aliquot_index) { |n| n }
  end
end
