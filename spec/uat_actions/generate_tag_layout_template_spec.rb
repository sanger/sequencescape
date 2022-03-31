# frozen_string_literal: true

require 'rails_helper'

describe UatActions::GenerateTagLayoutTemplate do
  context 'with valid options' do
    let(:tag_count) { 96 }
    let(:tag_group) { create :tag_group, tag_count: tag_count }
    let(:tag2_group) { create :tag_group, tag_count: tag_count }

    let(:parameters) do
      {
        name: 'Test Tag Layout Template',
        tag_group_name: tag_group.name,
        tag2_group_name: tag2_group.name,
        direction_algorithm: 'TagLayout::InColumns'
      }
    end
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { name: 'Test Tag Layout Template' }
    end

    context 'with both tag groups' do
      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report).to eq report
      end
    end

    context 'without the tag2 group' do
      let(:parameters) do
        {
          name: 'Test Tag Layout Template',
          tag_group_name: tag_group.name,
          tag2_group_name: nil,
          direction_algorithm: 'TagLayout::InColumns'
        }
      end

      it 'can be performed' do
        expect(uat_action.perform).to be true
        expect(uat_action.report).to eq report
      end
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
