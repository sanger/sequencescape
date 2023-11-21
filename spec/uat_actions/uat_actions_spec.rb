# frozen_string_literal: true
require 'rails_helper'

# Test classes for UatActions
class UatActions::GeneratePlates < UatActions
  self.title = 'Generate plates'
end

class UatActions::GenerateTubes < UatActions
  self.title = 'Generate tubes'
end

class UatActions::GeneratePlateTags < UatActions
  self.title = 'Generate plate tags'
end

class UatActions::GenerateTagPlates < UatActions
  self.title = 'Generate tag plates'
end

class UatActions::GenerateBananas < UatActions
  self.title = 'Generate bananas'
end

RSpec.describe UatActions, type: :model do
  let(:generate_plates) { UatActions::GeneratePlates }
  let(:generate_tubes) { UatActions::GenerateTubes }
  let(:generate_plate_tags) { UatActions::GeneratePlateTags }
  let(:generate_tag_plates) { UatActions::GenerateTagPlates }
  let(:generate_bananas) { UatActions::GenerateBananas }

  let(:uat_actions) { [generate_plates, generate_tubes, generate_plate_tags, generate_tag_plates, generate_bananas] }

  describe '.category' do
    let(:expected_category) { %w[Plate Tube Tag Tag Miscellaneous] }

    it 'returns the category of the UatAction item by item' do
      uat_actions.each { |uat_action| expect(uat_action.category).to eq(expected_category.shift) }
    end
  end

  describe '.grouped_and_sorted_uat_actions' do
    let(:grouped_and_sorted_uat_actions) { described_class.grouped_and_sorted_uat_actions(uat_actions) }
    let(:expected_grouped_and_sorted_uat_actions) do
      {
        'Miscellaneous' => [generate_bananas],
        'Tag' => [generate_plate_tags, generate_tag_plates],
        'Plate' => [generate_plates],
        'Tube' => [generate_tubes]
      }
    end

    it 'returns grouped uat_actions' do
      grouped_and_sorted_uat_actions.each do |category, uat_actions|
        expect(uat_actions).to eq(expected_grouped_and_sorted_uat_actions[category])
      end
    end

    it 'returns sorted uat_actions' do
      # get the first item in the 2d array
      sorted_categories = grouped_and_sorted_uat_actions.pluck(0)
      expect(sorted_categories).to eq(%w[Tag Plate Tube Miscellaneous])
    end
  end
end
