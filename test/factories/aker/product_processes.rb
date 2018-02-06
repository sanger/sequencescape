FactoryGirl.define do
  factory :aker_product_process, class: Aker::ProductProcess do
    product { create(:aker_product) }
    process { create(:aker_process) }
    sequence(:stage) { |n| n }
  end
end
