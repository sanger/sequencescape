# frozen_string_literal: true

FactoryGirl.define do
  factory :item do
    name               { |_a| generate :item_name }
    sequence(:version) { |a| a }
    count              nil
    closed             false
  end
end
