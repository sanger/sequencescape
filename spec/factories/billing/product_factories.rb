# frozen_string_literal: true

FactoryBot.define do
  factory :billing_product, class: 'Billing::Product' do
    billing_product_catalogue
    sequence(:name) { |n| "Product #{n}" }
    identifier { 'test' }
    category { 'sequencing' }

    factory :library_creation_billing_product do
      category { 'library_creation' }
    end
  end
end
