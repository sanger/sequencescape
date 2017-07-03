FactoryGirl.define do
  factory :work_order, class: Aker::WorkOrder do
    sequence(:aker_id) { |n| n }
  end
end
