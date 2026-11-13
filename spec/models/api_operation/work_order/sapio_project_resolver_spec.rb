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
end
