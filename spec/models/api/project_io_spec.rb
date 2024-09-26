# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::ProjectIO do
  context 'with minimal details' do
    subject { create(:project, approved: true) }

    let(:metadata) { subject.project_metadata }

    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'name' => subject.name,
        'approved' => true,
        'state' => subject.state,
        'cost_code' => metadata.project_cost_code,
        'funding_comments' => nil,
        'collaborators' => nil,
        'external_funding_source' => nil,
        'budget_cost_centre' => nil,
        'funding_model' => 'Internal',
        'project_manager' => 'Unallocated',
        'budget_division' => metadata.budget_division.name
      }
    end

    it_behaves_like('an IO object')
  end

  context 'with roles and collaborators' do
    subject do
      create(
        :project,
        approved: true,
        project_metadata_attributes: {
          collaborators: 'Test',
          external_funding_source: 'Tooth fairy',
          sequencing_budget_cost_centre: '123',
          funding_comments: 'It is funded',
          project_manager: project_manager
        }
      )
    end

    let(:project_manager) { create(:project_manager) }
    let!(:manager) { create(:manager, authorizable: subject) }

    let(:metadata) { subject.project_metadata }

    let(:expected_json) do
      {
        'uuid' => subject.uuid,
        'id' => subject.id,
        'name' => subject.name,
        'approved' => true,
        'state' => subject.state,
        'cost_code' => metadata.project_cost_code,
        'funding_comments' => 'It is funded',
        'collaborators' => 'Test',
        'external_funding_source' => 'Tooth fairy',
        'budget_cost_centre' => '123',
        'funding_model' => 'Internal',
        'project_manager' => project_manager.name,
        'budget_division' => metadata.budget_division.name,
        'manager' => [{ login: manager.login, email: manager.email, name: manager.name }]
      }
    end

    it_behaves_like('an IO object')
  end
end
