# frozen_string_literal: true
require 'rails_helper'

class StudyHelperTestUatAction < UatActions
  include UatActions::Shared::StudyHelper

  form_field :study_name,
             :select,
             label: 'Study',
             help: 'The study under which samples begin. List includes all active studies.',
             select_options: -> { Study.active.alphabetical.pluck(:name) }
end

RSpec.describe UatActions::Shared::StudyHelper do
  subject(:uat_action) { StudyHelperTestUatAction.new(parameters) }

  context 'when study_name is specified' do
    let(:study_name) { 'test-study-name' }
    let(:parameters) { { study_name: } }

    context 'when the study exists' do
      before { create(:study, name: study_name) }

      it 'returns the study' do
        expect(uat_action.send(:study)).to eq(Study.find_by(name: study_name))
      end
    end

    context 'when the study does not exist' do
      it 'adds an error' do # rubocop:disable RSpec/MultipleExpectations
        expect(uat_action).not_to be_valid
        expect(uat_action.errors[:study_name]).to include(
          format(described_class::ERROR_STUDY_DOES_NOT_EXIST, study_name)
        )
      end
    end
  end

  context 'when study_name is not specified' do
    let(:parameters) { {} } # i.e. { study_name: nil }

    it 'returns the default study' do
      expect(uat_action.send(:study)).to eq(UatActions::StaticRecords.study)
    end
  end
end
