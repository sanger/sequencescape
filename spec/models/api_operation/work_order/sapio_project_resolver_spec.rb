# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder::SapioProjectResolver do
  subject(:resolver) { described_class.new(' COST1 ') }

  it 'finds the existing project named after the cost code' do
    project = create(:project, name: 'SAPIO-COST1')
    expect(resolver.find_or_create).to eq(project)
  end

  it 'creates the project with the cost code when it does not exist' do
    expect(resolver.find_or_create).to have_attributes(name: 'SAPIO-COST1', project_cost_code: 'COST1')
  end

  it 'creates a project that submissions can be made for' do
    project = resolver.find_or_create
    expect(project).to have_attributes(approved?: true, active?: true, actionable?: true, submittable?: true)
  end

  it 'creates the project in the Sapio budget division with external funding' do
    expect(resolver.find_or_create.project_metadata).to have_attributes(
      budget_division: have_attributes(name: 'Sapio'), project_funding_model: 'External'
    )
  end
end
