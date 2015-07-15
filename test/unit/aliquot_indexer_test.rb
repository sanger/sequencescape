#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require "test_helper"

class AliquotIndexerTest < ActiveSupport::TestCase

  context "when given a sensible number of aliquots" do
    setup do
      @pre_count = AliquotIndex.count
      @lane = Factory :lane
      @tags = [1,8,2,4].map {|map_id| Factory :tag, :map_id => map_id }
      @tag2s = [1,2].map {|map_id| Factory :tag, :map_id => map_id }*2
      @aliquots = 4.times.map {|i| Factory :aliquot, :receptacle => @lane, :tag=>@tags[i], :tag2=>@tag2s[i] }

      @aliquot_index = [1,4,2,3]
    end

    should "Apply consecutive tags from 1" do
      AliquotIndexer.index(@lane)

      assert_equal 4, AliquotIndex.count - @pre_count, "#{AliquotIndex.count} indexes were created, 4 expected"

      new_indexes = AliquotIndex.find_all_by_lane_id(@lane.id)
      assert_equal 4, new_indexes.count,  "#{new_indexes.count} indexes belonged to the lane, 4 expected"

      new_indexes.each do |ai|
        aliquot_number = @aliquots.index(ai.aliquot)
        expected_index = @aliquot_index[aliquot_number]
        actual_index   = ai.aliquot_index
        assert_equal expected_index, ai.aliquot_index, "Aliquot #{aliquot_number} given index #{actual_index}, expected #{expected_index}"
      end

    end

    context "when phix is added" do

      setup do
        @phix = Factory :spiked_buffer do |sb|
          sb.aliquots {|a| a.association(:aliquot, :receptacle => sb, :tag=>@tags[2]) }
        end
        a = Factory :aliquot, :receptacle => @phix, :tag=>@tags[2]
        @phix.aliquots = [a]
        @lane.parents << @phix
        @aliquot_index = [1,5,3,4]
      end

      should "skip the phix map_id" do
        AliquotIndexer.index(@lane)

        assert_equal 4, AliquotIndex.count - @pre_count, "#{AliquotIndex.count} indexes were created, 4 expected"

        new_indexes = AliquotIndex.find_all_by_lane_id(@lane.id)
        assert_equal 4, new_indexes.count,  "#{new_indexes.count} indexes belonged to the lane, 4 expected"

        new_indexes.each do |ai|
          aliquot_number = @aliquots.index(ai.aliquot)
          expected_index = @aliquot_index[aliquot_number]
          actual_index   = ai.aliquot_index
          assert_equal expected_index, ai.aliquot_index, "Aliquot #{aliquot_number} given index #{actual_index}, expected #{expected_index}"
        end
      end
    end

  end

end
