# frozen_string_literal: true

FactoryBot.define do
  factory :racked_tube do
    tube
    tube_rack
    coordinate { 'A1' }
  end
end
