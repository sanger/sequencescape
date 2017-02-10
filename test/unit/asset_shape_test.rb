# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

require 'test_helper'

class AssetShapeTest < ActiveSupport::TestCase
  context 'standard plates of' do
    setup do
      @shape = AssetShape.new(name: 'Test', horizontal_ratio: 3, vertical_ratio: 2, description_strategy: 'Map::Coordinate')
    end

  context '96 wells ' do
    context 'conversion between horizontal and back' do
      (1..96).step(1) do |i|
        should "revert to same value #{i}" do
          assert_equal i, @shape.vertical_to_horizontal(@shape.horizontal_to_vertical(i, 96), 96)
          assert_equal i, @shape.horizontal_to_vertical(@shape.vertical_to_horizontal(i, 96), 96)
        end
      end
    end

    { 1 => 1, 2 => 9, 96 => 96, 51 => 21, 85 => 8 }.each do |hor, vert|
      should "map horizontal #{hor} to vertical #{vert}" do
        assert_equal vert, @shape.horizontal_to_vertical(hor, 96)
      end
      should "map vertical #{vert} to horizontal #{hor}" do
        assert_equal hor, @shape.vertical_to_horizontal(vert, 96)
      end
    end
  end

  context '384 wells ' do
    context 'and back' do
      (1..384).step(1) do |i|
        should "revert back to same value #{i}" do
          assert_equal i, @shape.vertical_to_horizontal(@shape.horizontal_to_vertical(i, 384), 384)
          assert_equal i, @shape.horizontal_to_vertical(@shape.vertical_to_horizontal(i, 384), 384)
        end
      end
    end

    { 1 => 1, 2 => 17, 384 => 384, 370 => 160, 26 => 18 }.each do |hor, vert|
      should "map horizontal #{hor} to vertical #{vert}" do
        assert_equal vert, @shape.horizontal_to_vertical(hor, 384)
      end
      should "map vertical #{vert} to horizontal #{hor}" do
        assert_equal hor, @shape.vertical_to_horizontal(vert, 384)
      end
    end
  end
  end

  context 'Fluidigm plates of 96 wells' do
    setup do
      @shape = AssetShape.new(name: 'Test', horizontal_ratio: 3, vertical_ratio: 8, description_strategy: 'Map::Sequential')
    end

    context 'conversion between horizontal and back' do
      (1..96).step(1) do |i|
        should "revert to same value #{i}" do
          assert_equal i, @shape.vertical_to_horizontal(@shape.horizontal_to_vertical(i, 96), 96)
          assert_equal i, @shape.horizontal_to_vertical(@shape.vertical_to_horizontal(i, 96), 96)
        end
      end
    end

    { 1 => 1, 2 => 17, 96 => 96, 51 => 41, 85 => 15 }.each do |hor, vert|
      should "map horizontal #{hor} to vertical #{vert}" do
        assert_equal vert, @shape.horizontal_to_vertical(hor, 96)
      end
      should "map vertical #{vert} to horizontal #{hor}" do
        assert_equal hor, @shape.vertical_to_horizontal(vert, 96)
      end
    end

    { 1 => 1, 13 => 2, 7 => 49, 2 => 9, 96 => 96 }.each do |hor, vert|
      should "map interlaced vertical #{vert} to horizontal #{hor}" do
        assert_equal hor, @shape.interlaced_vertical_to_horizontal(vert, 96)
      end
    end
  end

  context 'Fluidigm plates of 192 wells' do
    setup do
      @shape = AssetShape.new(name: 'Test', horizontal_ratio: 3, vertical_ratio: 4, description_strategy: 'Map::Sequential')
    end

    context 'conversion between horizontal and back' do
      (1..96).step(1) do |i|
        should "revert to same value #{i}" do
          assert_equal i, @shape.vertical_to_horizontal(@shape.horizontal_to_vertical(i, 192), 192)
          assert_equal i, @shape.horizontal_to_vertical(@shape.vertical_to_horizontal(i, 192), 192)
        end
      end
    end

    { 1 => 1, 2 => 17, 192 => 192, 51 => 37, 85 => 8 }.each do |hor, vert|
      should "map horizontal #{hor} to vertical #{vert}" do
        assert_equal vert, @shape.horizontal_to_vertical(hor, 192)
      end
      should "map vertical #{vert} to horizontal #{hor}" do
        assert_equal hor, @shape.vertical_to_horizontal(vert, 192)
      end
    end

    # {1=>1, 7=>97, 96=>84, 13=>2, 2=>17}.each do |hor,vert|
    #   should "map interlaced vertical #{vert} to horizontal #{hor}" do
    #     assert_equal hor, @shape.interlaced_vertical_to_horizontal(vert,192)
    #   end
    # end
  end
end
