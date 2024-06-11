# frozen_string_literal: true

FactoryBot.define do
  factory :budget_division do
    name { |_a| generate(:budget_division_name) }
  end

  factory :project_metadata, class: 'Project::Metadata' do
    project_cost_code { 'Some Cost Code' }
    project_funding_model { 'Internal' }
    budget_division
  end
end
