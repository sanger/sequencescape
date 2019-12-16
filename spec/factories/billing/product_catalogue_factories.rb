# frozen_string_literal: true

FactoryBot.define do
  factory :billing_product_catalogue, class: 'Billing::ProductCatalogue' do
    sequence(:name) { |n| "product_catalogue_#{n}" }
  end

  factory :miseq_paired_end_product_catalogue, class: 'Billing::ProductCatalogue' do
    name { :miseq_paired_end }
    after(:create) do |catalogue|
      catalogue.billing_products.create!([
        { name: 'product_with_read_length_150', identifier: 150, category: 'sequencing' },
        { name: 'product_with_read_length_175', identifier: 175, category: 'sequencing' }
      ])
    end
  end
end
