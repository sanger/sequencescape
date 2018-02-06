FactoryGirl.define do
  factory :aker_process_module, class: Aker::ProcessModule do
    sequence(:name) { |n| "ProcessModule#{n}" }
  end
end
