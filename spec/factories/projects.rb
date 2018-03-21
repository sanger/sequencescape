# frozen_string_literal: true

FactoryGirl.define do
  factory :project do
    name                { generate :project_name }
    enforce_quotas      false
    approved            true
    state               'active'
    project_metadata

    factory :project_with_order do
      after(:build) { |project| project.orders ||= [create(:order, project: project)] }
    end
  end
end
