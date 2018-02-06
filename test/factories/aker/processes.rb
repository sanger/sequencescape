FactoryGirl.define do
  factory :aker_process, class: Aker::Process do
    sequence(:name) { |n| "Process#{n}" }
    turnaround_time 5

    factory :aker_process_with_process_module_pairings do
      transient do
        number_of_pairs 3
      end

      after(:create) do |process, evaluator|
        process.process_module_pairings = create_list(:aker_process_module_pairing, evaluator.number_of_pairs, process: process)
      end
    end
  end
end
