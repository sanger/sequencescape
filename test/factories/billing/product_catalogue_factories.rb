FactoryGirl.define do
  factory :billing_product_catalogue, class: Billing::ProductCatalogue do
    sequence(:name) { |n| "product_catalogue_#{n}" }
    differentiator :read_length
  end

  factory :miseq_paired_end_product_catalogue, class: Billing::ProductCatalogue do
    name :miseq_paired_end
    differentiator :read_length
    after(:create) do |catalogue|
      catalogue.billing_products.create!([
        { name: 'product_with_read_length_150', differentiator_value: 150 },
        { name: 'product_with_read_length_175', differentiator_value: 175 }
      ])
    end
  end
end
