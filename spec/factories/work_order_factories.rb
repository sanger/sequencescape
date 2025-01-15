# frozen_string_literal: true

FactoryBot.define do
  factory :work_order_type do
    sequence(:name) { |i| "work_order_#{i}" }
  end

  factory :work_order do
    requests { create_list(:customer_request, 1) }
    state { 'pending' }
    work_order_type
  end
end
