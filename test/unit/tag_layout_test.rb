require 'test_helper'
# Looking for other layout tests: features/api/tag_layouts.feature
class TagLayoutTest < ActiveSupport::TestCase
  def generate_tag_layout(plate)
    Hash[plate.wells.with_aliquots.map { |w| [w.map_description, w.aliquots.map { |a| a.tag.map_id }] }]
  end
  context 'TagLayout' do
    setup do
      @plate = create :plate_with_untagged_wells
      @tag_group = create :tag_group, tag_count: 32
      @user = create :user
      @initial_tag = 0
    end

    context 'by column' do
      setup do
        @direction = 'column'
      end

      context 'manual by plate' do
        setup do
          @walking_by = 'manual by plate'
        end

        should 'order by column and plate' do
          @expected_tag_layout = { 'A1' => [1], 'B1' => [2], 'C1' => [3], 'D1' => [4], 'E1' => [5], 'F1' => [6], 'G1' => [7], 'H1' => [8] }
        end
      end

      context 'grouped by plate' do
        setup do
          @walking_by = 'as group by plate'
        end

        context 'with no offset' do
          should 'apply multiple tags' do
            @expected_tag_layout = { 'A1' => [1, 2, 3, 4], 'B1' => [5, 6, 7, 8], 'C1' => [9, 10, 11, 12], 'D1' => [13, 14, 15, 16], 'E1' => [17, 18, 19, 20], 'F1' => [21, 22, 23, 24], 'G1' => [25, 26, 27, 28], 'H1' => [29, 30, 31, 32] }
          end
        end

        context 'with an initial_tag' do
          setup do
            @initial_tag = 4
          end
          should 'apply multiple tags with an offset' do
            @expected_tag_layout = { 'H1' => [1, 2, 3, 4], 'A1' => [5, 6, 7, 8], 'B1' => [9, 10, 11, 12], 'C1' => [13, 14, 15, 16], 'D1' => [17, 18, 19, 20], 'E1' => [21, 22, 23, 24], 'F1' => [25, 26, 27, 28], 'G1' => [29, 30, 31, 32] }
          end
        end
      end
    end

    teardown do
      # TagLayout.create!(plate: @plate, user: @user, tag_group: @tag_group, walking_by: @walking_by, direction: @direction, initial_tag: @initial_tag)
      # assert_equal @expected_tag_layout, generate_tag_layout(@plate)
    end
  end
end
