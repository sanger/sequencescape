# frozen_string_literal: true

require 'test_helper'

class AliquotIndexerTest < ActiveSupport::TestCase
  context 'when given a sensible number of aliquots' do
    context 'which are dual indexed' do
      setup do
        @pre_count = AliquotIndex.count
        @lane = create(:lane)
        @tags = [1, 8, 2, 4].map { |map_id| create(:tag, map_id:) }
        @tag2s = [1, 2].map { |map_id| create(:tag, map_id:) } * 2
        @aliquots = Array.new(4) { |i| create(:aliquot, receptacle: @lane, tag: @tags[i], tag2: @tag2s[i]) }

        @aliquot_index = [1, 4, 2, 3]
      end

      should 'Apply consecutive tags from 1' do
        AliquotIndexer.index(@lane)

        assert_equal 4, AliquotIndex.count - @pre_count, "#{AliquotIndex.count} indexes were created, 4 expected"

        new_indexes = AliquotIndex.where(lane_id: @lane.id)

        assert_equal 4, new_indexes.count, "#{new_indexes.count} indexes belonged to the lane, 4 expected"

        new_indexes.each do |ai|
          aliquot_number = @aliquots.index(ai.aliquot)
          expected_index = @aliquot_index[aliquot_number]
          actual_index = ai.aliquot_index

          assert_equal expected_index,
                       ai.aliquot_index,
                       "Aliquot #{aliquot_number} given index #{actual_index}, expected #{expected_index}"
        end
      end

      context 'when phix is added' do
        setup do
          @phix = create(:spiked_buffer, aliquot_attributes: { tag: @tags[2], tag2: nil })
          @lane.labware.parents << @phix
          @aliquot_index = [1, 5, 3, 4]
        end

        should 'skip the phix map_id' do
          AliquotIndexer.index(@lane)

          assert_equal 4, AliquotIndex.count - @pre_count, "#{AliquotIndex.count} indexes were created, 4 expected"

          new_indexes = AliquotIndex.where(lane_id: @lane.id)

          assert_equal 4, new_indexes.count, "#{new_indexes.count} indexes belonged to the lane, 4 expected"

          new_indexes.each do |ai|
            aliquot_number = @aliquots.index(ai.aliquot)
            expected_index = @aliquot_index[aliquot_number]
            actual_index = ai.aliquot_index

            assert_equal expected_index,
                         ai.aliquot_index,
                         "Aliquot #{aliquot_number} given index #{actual_index}, expected #{expected_index}"
          end
        end
      end
    end

    context 'which are single indexed' do
      setup do
        @pre_count = AliquotIndex.count
        @lane = create(:lane)
        @tags = [1, 8, 2, 4].map { |map_id| create(:tag, map_id:) }
        @aliquots = Array.new(4) { |i| create(:aliquot, receptacle: @lane, tag: @tags[i], tag2_id: -1) }

        @aliquot_index = [1, 4, 2, 3]
      end

      should 'Apply consecutive tags from 1' do
        AliquotIndexer.index(@lane)

        assert_equal 4, AliquotIndex.count - @pre_count, "#{AliquotIndex.count} indexes were created, 4 expected"

        new_indexes = AliquotIndex.where(lane_id: @lane.id)

        assert_equal 4, new_indexes.count, "#{new_indexes.count} indexes belonged to the lane, 4 expected"

        new_indexes.each do |ai|
          aliquot_number = @aliquots.index(ai.aliquot)
          expected_index = @aliquot_index[aliquot_number]
          actual_index = ai.aliquot_index

          assert_equal expected_index,
                       ai.aliquot_index,
                       "Aliquot #{aliquot_number} given index #{actual_index}, expected #{expected_index}"
        end
      end

      context 'when phix is added' do
        setup do
          @phix = create(:spiked_buffer, aliquot_attributes: { tag: @tags[2], tag2: nil })
          @lane.labware.parents << @phix
          @aliquot_index = [1, 5, 3, 4]
        end

        should 'skip the phix map_id' do
          AliquotIndexer.index(@lane)

          assert_equal 4, AliquotIndex.count - @pre_count, "#{AliquotIndex.count} indexes were created, 4 expected"

          new_indexes = AliquotIndex.where(lane_id: @lane.id)

          assert_equal 4, new_indexes.count, "#{new_indexes.count} indexes belonged to the lane, 4 expected"

          new_indexes.each do |ai|
            aliquot_number = @aliquots.index(ai.aliquot)
            expected_index = @aliquot_index[aliquot_number]
            actual_index = ai.aliquot_index

            assert_equal expected_index,
                         ai.aliquot_index,
                         "Aliquot #{aliquot_number} given index #{actual_index}, expected #{expected_index}"
          end
        end
      end
    end

    context 'which are single indexed with i5 (tag2) tags' do
      setup do
        @pre_count = AliquotIndex.count
        @lane = create(:lane)
        @tags = [1, 8, 2, 4].map { |map_id| create(:tag, map_id:) }
        @aliquots = Array.new(4) { |i| create(:aliquot, receptacle: @lane, tag_id: -1, tag2: @tags[i]) }

        @aliquot_index = [1, 4, 2, 3]
      end

      should 'Apply consecutive tags from 1' do
        AliquotIndexer.index(@lane)

        assert_equal 4, AliquotIndex.count - @pre_count, "#{AliquotIndex.count} indexes were created, 4 expected"

        new_indexes = AliquotIndex.where(lane_id: @lane.id)

        assert_equal 4, new_indexes.count, "#{new_indexes.count} indexes belonged to the lane, 4 expected"

        new_indexes.each do |ai|
          aliquot_number = @aliquots.index(ai.aliquot)
          expected_index = @aliquot_index[aliquot_number]
          actual_index = ai.aliquot_index

          assert_equal expected_index,
                       ai.aliquot_index,
                       "Aliquot #{aliquot_number} given index #{actual_index}, expected #{expected_index}"
        end
      end

      context 'when phix is added' do
        setup do
          @phix = create(:spiked_buffer, aliquot_attributes: { tag: @tags[2], tag2: nil })
          @lane.labware.parents << @phix
          @aliquot_index = [1, 5, 3, 4]
        end

        should 'skip the phix map_id' do
          AliquotIndexer.index(@lane)

          assert_equal 4, AliquotIndex.count - @pre_count, "#{AliquotIndex.count} indexes were created, 4 expected"

          new_indexes = AliquotIndex.where(lane_id: @lane.id)

          assert_equal 4, new_indexes.count, "#{new_indexes.count} indexes belonged to the lane, 4 expected"

          new_indexes.each do |ai|
            aliquot_number = @aliquots.index(ai.aliquot)
            expected_index = @aliquot_index[aliquot_number]
            actual_index = ai.aliquot_index

            assert_equal expected_index,
                         ai.aliquot_index,
                         "Aliquot #{aliquot_number} given index #{actual_index}, expected #{expected_index}"
          end
        end
      end
    end
  end
end
