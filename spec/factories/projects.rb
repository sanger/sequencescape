# frozen_string_literal: true

FactoryBot.define do
  factory :project do
    name { generate(:project_name) }
    enforce_quotas { false }
    approved { true }
    state { 'active' }
    project_metadata

    factory :project_with_order do
      after(:build) { |project| project.orders ||= [create(:order, project:)] }
    end
  end

  factory :project_manager do
    sequence(:name) { |i| "Project Manager #{i}" }
  end
end
