FactoryGirl.define do
  factory :billing_product_catalogue, class: Billing::ProductCatalogue do
    sequence(:name) { |n| "product_catalogue_#{n}" }
    differentiator :read_length
  end
end
