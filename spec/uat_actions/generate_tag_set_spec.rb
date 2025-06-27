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

    context 'when tag set already exists' do
      # NB. The UAT action checks the name of the tag set, not the tag groups.
      # The report will include the tag group names of the existing tag set.
      let!(:existing_tag_set) { create(:tag_set, name: 'Test Tag Set') }
      let!(:existing_report) do
        { name: 'Test Tag Set',
          tag_group_name: existing_tag_set.tag_group.name,
          tag2_group_name: existing_tag_set.tag2_group.name }
      end
      let(:uat_action) { described_class.new(parameters) }

      it 'does not create a new tag set' do # rubocop:disable RSpec/MultipleExpectations
        expect { uat_action.perform }.not_to change(TagSet, :count)
        expect(uat_action.report).to eq existing_report
      end
    end
  end

  context 'with invalid options' do
    context 'when name is missing' do
      let(:parameters) do
        {
          tag_group_name: 'Some Tag Group',
          tag2_group_name: 'Some Tag2 Group'
        }
      end
      let(:uat_action) { described_class.new(parameters) }

      it 'sets an error message' do # rubocop:disable RSpec/MultipleExpectations
        expect(uat_action.valid?).to be false
        expect(uat_action.errors[:name]).to include("can't be blank")
      end
    end
  end
end
