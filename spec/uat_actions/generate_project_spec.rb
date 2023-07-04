# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateProject do
  context 'with valid options' do
    let(:uat_action) { described_class.new(parameters) }
    let(:project_name) { 'Test Project' }
    let(:project_cost_code) { '1234' }
    let(:parameters) { { project_name: project_name, project_cost_code: project_cost_code } }

    describe '#perform' do
      context 'when generating a project' do
        it 'generates a project' do
          expect { uat_action.perform }.to(change { Project.all.count }.by(1))
        end

        it 'creates the project with the correct data' do
          uat_action.perform
          expect(Project.last.name).to eq project_name
        end
      end
    end
  end

  describe '#default' do
    it 'returns a default' do
      expect(described_class.default).to be_a described_class
    end
  end
end
