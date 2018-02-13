# frozen_string_literal: true

FactoryGirl.define do
  factory :aker_work_order_json, class: Hash do
    skip_create

    transient do
      study { create(:study) }
    end

    sequence(:work_order_id) { |n| n }
    product_name '30x Human Whole Genome Shotgun (WGS) with PCR'
    product_version 20170324
    product_uuid { SecureRandom.uuid }
    project_uuid { SecureRandom.uuid }
    project_name 'MyProject'
    cost_code 'S1234'
    status 'active'
    data_release_uuid { study.uuid }
    comment 'Cook for 20 minutes.'
    desired_date '2017-08-01'
    materials { [build(:material_json).with_indifferent_access, build(:material_json, container_has_an_address: true).with_indifferent_access] }

    initialize_with { attributes.stringify_keys }

    after(:build) do |work_order, evaluator|
      work_order['data_release_uuid'] = evaluator.study.uuid if evaluator.study.present?
    end
  end
end
