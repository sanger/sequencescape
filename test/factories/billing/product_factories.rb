FactoryGirl.define do
  factory :billing_product, class: Billing::Product do
    billing_product_catalogue
    sequence(:name) { |n| "Product #{n}" }
    differentiator_value 'test'
  end
end
