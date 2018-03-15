# frozen_string_literal: true

FactoryGirl.define do
  factory(:product_line) do
    sequence(:name) { |n| "ProductLine#{n}" }
  end
end
