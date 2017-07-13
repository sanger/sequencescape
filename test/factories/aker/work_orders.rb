FactoryGirl.define do
  factory :work_order, class: Aker::WorkOrder do
    sequence(:aker_id) { |n| n }

    factory :work_order_with_samples do

      samples { create_list(:sample_for_work_order, 5) }
    end
  end
end
