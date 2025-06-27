# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateTagSet do
  context 'with valid options' do
    let(:tag_group) { create(:tag_group, tag_count: 96) }
    let(:tag2_group) { create(:tag_group, tag_count: 96) }

    let(:parameters) do
      {
        name: 'Test Tag Set',
        tag_group_name: tag_group.name,
        tag2_group_name: tag2_group.name
      }
    end
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      { name: 'Test Tag Set', tag_group_name: tag_group.name, tag2_group_name: tag2_group.name }
    end

    context 'with both tag groups' do
      it 'can be performed' do # rubocop:disable RSpec/MultipleExpectations
        expect(uat_action.perform).to be true
        expect(uat_action.report).to eq report
      end
    end

    context 'without the tag2 group' do
      let(:parameters) do
        {
          name: 'Test Tag Set',
          tag_group_name: tag_group.name
        }
      end
      let(:report) do
        { name: 'Test Tag Set', tag_group_name: tag_group.name, tag2_group_name: nil }
      end

      it 'can be performed' do # rubocop:disable RSpec/MultipleExpectations
        expect(uat_action.perform).to be true
        expect(uat_action.report).to eq report
      end
    end
  end
end
