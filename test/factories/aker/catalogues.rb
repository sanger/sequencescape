FactoryGirl.define do
  factory :aker_catalogue, class: Aker::Catalogue do
    pipeline 'WGS'
    lims_id 'SQSC'

    factory :aker_catalogue_with_product_and_process_module_pairings do
      transient do
        number_of_pairs 3
      end

      after(:create) do |catalogue, evaluator|
        create(:aker_product_with_process_module_pairings, number_of_pairs: evaluator.number_of_pairs, catalogue: catalogue)
      end
    end
  end
end
