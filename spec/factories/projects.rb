# frozen_string_literal: true

FactoryGirl.define do
  factory :project do
    name                { |_p| generate :project_name }
    enforce_quotas      false
    approved            true
    state               'active'

    after(:build) { |project| project.project_metadata = create(:project_metadata, project: project) }

    factory :project_with_order do
      after(:build) { |project| project.orders ||= [create(:order, project: project)] }
    end
  end
end
