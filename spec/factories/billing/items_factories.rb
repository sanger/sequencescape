# frozen_string_literal: true

FactoryBot.define do
  factory :billing_item, class: 'Billing::Item' do
    request
    project_cost_code { 'cost_code' }
    units { '30' }
    billing_product_code { 'L1000' }
    billing_product_description { 'Some description' }
    request_passed_date { '20170727' }
  end
end
