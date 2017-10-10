FactoryGirl.define do
  factory :billing_product, class: Billing::Product do
    billing_product_catalogue
    sequence(:name) { |n| "Product #{n}" }
    identifier 'test'
    category 'sequencing'
  end
end
