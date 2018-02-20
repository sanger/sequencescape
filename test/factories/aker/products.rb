FactoryGirl.define do
  factory :aker_product, class: Aker::Product do
    catalogue { create(:aker_catalogue) }
    sequence(:name) { |n| "Product#{n}" }
    description 'This is a product'
    requested_biomaterial_type 'blood'
    product_class 'genotyping'

    factory :aker_product_with_process_module_pairings do
      transient do
        number_of_pairs 3
      end

      after(:create) do |product, evaluator|
        product_process = create(:aker_product_process, product: product)
        create_list(:aker_process_module_pairing, evaluator.number_of_pairs, process: product_process.process)
      end
    end
  end
end
