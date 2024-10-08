# frozen_string_literal: true

FactoryBot.define do
  factory :product_catalogue do
    name { |_x| FactoryBot.generate(:product_catalogue_name) }

    factory :single_product_catalogue do
      selection_behaviour { 'SingleProduct' }
    end

    factory :library_driven_product_catalogue do
      selection_behaviour { 'LibraryDriven' }
    end
  end

  factory :product do
    name { FactoryBot.generate(:product_name) }
    deprecated_at { nil }
  end

  factory :product_criteria do
    product
    stage { 'stock' }
    behaviour { 'Basic' }
    configuration { { total_micrograms: { greater_than: 50 }, sanger_sample_id: {} } }
  end

  factory :product_product_catalogue do
    product
    product_catalogue
  end
end
