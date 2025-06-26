# frozen_string_literal: true
require 'rails_helper'

# Test classes for UatActions
class UatActions::GenerateLabware < UatActions
  self.title = 'Generate labware'
  self.category = :generating_samples
end

class UatActions::TestField < UatActions
  self.title = 'Test field'
  self.category = :setup_and_test
end

class UatActions::TestForm < UatActions
  self.title = 'Test form'
  self.category = :setup_and_test
end

class UatActions::GenerateUncategorised < UatActions
  self.title = 'Generate uncategorised'
end

class UatActions::GenerateBananas < UatActions
  self.title = 'Generate bananas'
  self.category = :unknown_category
end

RSpec.describe UatActions, type: :model do
  let(:generate_labware) { UatActions::GenerateLabware }
  let(:test_field) { UatActions::TestField }
  let(:test_form) { UatActions::TestForm }
  let(:generate_uncategorised) { UatActions::GenerateUncategorised }
  let(:generate_bananas) { UatActions::GenerateBananas }

  describe '.category' do
    let(:uat_actions) { [generate_labware, test_field, test_form, generate_uncategorised, generate_bananas] }
    let(:expected_category) { %i[generating_samples setup_and_test setup_and_test uncategorised unknown_category] }

    it 'returns the categories of the UatActions' do
      uat_action_categories = uat_actions.map(&:category)
      expect(uat_action_categories).to eq(expected_category)
    end
  end

  describe '.grouped_and_sorted_uat_actions (expecting errors)' do
    before { allow(described_class).to receive(:all).and_return(uat_actions) }

    # uat_actions with erroneous actions
    let(:uat_actions) { [generate_labware, test_field, test_form, generate_uncategorised, generate_bananas] }

    it 'raises an error if a UatAction has a category not in the list' do
      expect { described_class.grouped_and_sorted_uat_actions }.to raise_error(RuntimeError)
      expect { described_class.grouped_and_sorted_uat_actions }.to raise_error(
        "Category 'unknown_category' from 'UatActions::GenerateBananas' is not in the list of categories " \
        "#{UatActions::CATEGORY_LIST}"
      )
    end
  end

  describe '.grouped_and_sorted_uat_actions' do
    before { allow(described_class).to receive(:all).and_return(uat_actions) }

    # uat_actions without erroneous actions
    let(:uat_actions) { [generate_labware, test_field, test_form, generate_uncategorised] }

    let(:grouped_and_sorted_uat_actions) { described_class.grouped_and_sorted_uat_actions }
    let(:expected_grouped_and_sorted_uat_actions) do
      {
        setup_and_test: [test_field, test_form],
        generating_samples: [generate_labware],
        uncategorised: [generate_uncategorised]
      }
    end

    it 'returns grouped uat_actions' do
      expect(grouped_and_sorted_uat_actions).to be_a(Array)
      grouped_and_sorted_uat_actions.each do |category, actions|
        expect(actions).to eq(expected_grouped_and_sorted_uat_actions[category])
      end
    end

    it 'returns sorted uat_actions' do
      # get the first item in the 2d array
      sorted_categories = grouped_and_sorted_uat_actions.pluck(0)
      expect(sorted_categories).to eq(%i[setup_and_test generating_samples uncategorised])
    end
  end
end
