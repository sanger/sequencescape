# frozen_string_literal: true

require 'rails_helper'

describe UatActions::ProjectInformation do
  subject(:uat_action) { described_class.new(project_name:) }

  let(:project_name) { 'Test Project' }

  context 'when the project exists' do
    let(:metadata) { create(:project_metadata, project_cost_code: '1234') }

    before { create(:project, name: 'Test Project', project_metadata: metadata) }

    it 'can be performed' do
      expect(uat_action.perform).to be true
    end

    it 'generates the expected report from project metadata' do
      uat_action.perform
      expect(uat_action.report).to eq(project_name: 'Test Project', project_cost_code: '1234')
    end

    it 'can be saved' do
      expect(uat_action.save).to be true
    end

    context 'when the project name has surrounding whitespace' do
      let(:project_name) { ' Test Project ' }

      it 'finds the project by its trimmed name' do
        uat_action.perform
        expect(uat_action.report[:project_cost_code]).to eq('1234')
      end
    end
  end

  context 'when the project name does not match a project' do
    it 'cannot be performed' do
      expect(uat_action.perform).to be false
    end

    it 'reports only the supplied project name' do
      uat_action.perform
      expect(uat_action.report).to eq(project_name: 'Test Project')
    end

    it 'reports a validation error' do
      uat_action.valid?
      expect(uat_action.errors[:project]).to include('could not be found')
    end
  end

  context 'when the project name is missing' do
    let(:project_name) { nil }

    it 'reports a validation error' do
      uat_action.valid?
      expect(uat_action.errors[:project_name]).to include('needs a value')
    end
  end

  it 'has only the project name form field' do
    expect(described_class.permitted).to eq([:project_name])
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
