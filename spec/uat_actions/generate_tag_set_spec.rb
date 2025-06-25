# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateTagSet do
  context 'with valid options' do
    let(:tag_group) { create(:tag_group) }
    let(:tag2_group) { create(:tag_group) }

    let(:parameters) do
      {
        name: 'Test Tag Set',
        tag_group_name: tag_group.name,
        tag2_group_name: tag2_group.name
      }
    end
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      { name: 'Test Tag Set' }
    end

    context 'with both tag groups' do
      it 'can be performed' do
        expect(uat_action.perform).to be true
      end

      it 'returns the expected report' do
        uat_action.perform
        expect(uat_action.report).to eq report
      end
    end

    context 'without the tag2 group' do
      let(:parameters) do
        {
          name: 'Test Tag Set',
          tag_group_name: tag_group.name,
          tag2_group_name: nil
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
      end

      it 'returns the expected report' do
        uat_action.perform
        expect(uat_action.report).to eq report
      end
    end
  end

  context 'with invalid options' do
    context 'when tag set name is missing' do
      let(:tag_group) { create(:tag_group, name: 'GroupA') }
      let(:tag2_group) { create(:tag_group, name: 'GroupB') }
      let(:params) { { tag_group_name: tag_group.name, tag2_group_name: tag2_group.name } }
      let(:uat_action) { described_class.new(params) }

      it 'is invalid' do
        expect(uat_action).not_to be_valid
      end

      it 'adds an error on name' do
        uat_action.valid?
        expect(uat_action.errors[:name]).to be_present
      end
    end

    context 'when tag group name is missing' do
      let(:tag2_group) { create(:tag_group, name: 'GroupB') }
      let(:params) { { name: 'Test Tag Set', tag2_group_name: tag2_group.name } }
      let(:uat_action) { described_class.new(params) }

      it 'is invalid' do
        expect(uat_action).not_to be_valid
      end

      it 'adds an error on tag_group_name' do
        uat_action.valid?
        expect(uat_action.errors[:tag_group_name]).to be_present
      end
    end

    context 'when tag group name and tag2 group name are the same' do
      let(:tag_group) { create(:tag_group, name: 'GroupA') }
      let(:params) { { name: 'Test Tag Set', tag_group_name: tag_group.name, tag2_group_name: tag_group.name } }
      let(:uat_action) { described_class.new(params) }

      it 'is invalid' do
        expect(uat_action).not_to be_valid
      end

      it 'adds an error on tag2_group_name' do
        uat_action.valid?
        expect(uat_action.errors[:tag2_group_name]).to be_present
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
