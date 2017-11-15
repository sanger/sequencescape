FactoryGirl.define do
  factory :work_order_type do
    sequence(:name) { |i| "work_order_#{i}" }
  end

  factory :work_order do
    work_order_type
    state 'pending'
  end
end
