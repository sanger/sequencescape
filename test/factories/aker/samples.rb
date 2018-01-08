FactoryGirl.define do
  factory :sample_for_work_order, class: Sample do
    sequence(:name) { |n| "2be2072d-7c96-49c3-b7ac-9c51d01c109b#{n}" }
    container
    sample_metadata { SampleMetadata.new(gender: 'male', donor_id: 'd', phenotype: 'p', sample_common_name: 'Mouse') }
  end
end
