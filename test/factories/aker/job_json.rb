# frozen_string_literal: true

FactoryGirl.define do
  factory :aker_job_json, class: Hash do
    skip_create

    transient do
      study { create(:study) }
    end

    sequence(:job_id) { |n| n }
    sequence(:work_order_id) { |n| n }
    product_name '30x Human Whole Genome Shotgun (WGS) with PCR'
    process_name 'Process name'
    process_uuid { SecureRandom.uuid }
    product_version 20170324
    product_uuid { SecureRandom.uuid }
    project_uuid { SecureRandom.uuid }
    project_name 'MyProject'
    cost_code 'S1234'
    data_release_uuid { study.uuid }
    modules { ['module 1', 'module 2'] }
    comment 'Cook for 20 minutes.'
    desired_date '2017-08-01'
    container { container }
    materials { [build(:material_json).with_indifferent_access,
        build(:material_json).with_indifferent_access] }

    initialize_with { attributes.stringify_keys }

    after(:build) do |work_order, evaluator|
      work_order['data_release_uuid'] = evaluator.study.uuid if evaluator.study.present?
    end
  end
end
