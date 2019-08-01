# frozen_string_literal: true

require 'test_helper'

class MapTest < ActiveSupport::TestCase
  context '96 wells ' do
    context 'conversion between horizontal and back' do
      (1..96).step(1) do |i|
        should "revert to same value #{i}" do
          assert_equal i, Map.vertical_to_horizontal(Map.horizontal_to_vertical(i, 96), 96)
          assert_equal i, Map.horizontal_to_vertical(Map.vertical_to_horizontal(i, 96), 96)
        end
      end
    end

    { 1 => 1, 2 => 9, 96 => 96, 51 => 21, 85 => 8 }.each do |hor, vert|
      should "map horizontal #{hor} to vertical #{vert}" do
        assert_equal vert, Map.horizontal_to_vertical(hor, 96)
      end
      should "map vertical #{vert} to horizontal #{hor}" do
        assert_equal hor, Map.vertical_to_horizontal(vert, 96)
      end
    end

    context 'Invalid well position' do
      [0, -1, 97, 384, '1'].each do |position|
        should "return nil for #{position.inspect}" do
          assert_nil Map.horizontal_to_vertical(position, 96)
        end
      end
    end
  end

  context '384 wells ' do
    context 'and back' do
      (1..384).step(1) do |i|
        should "revert back to same value #{i}" do
          assert_equal i, Map.vertical_to_horizontal(Map.horizontal_to_vertical(i, 384), 384)
          assert_equal i, Map.horizontal_to_vertical(Map.vertical_to_horizontal(i, 384), 384)
        end
      end
    end

    { 1 => 1, 2 => 17, 384 => 384, 370 => 160, 26 => 18 }.each do |hor, vert|
      should "map horizontal #{hor} to vertical #{vert}" do
        assert_equal vert, Map.horizontal_to_vertical(hor, 384)
      end
      should "map vertical #{vert} to horizontal #{hor}" do
        assert_equal hor, Map.vertical_to_horizontal(vert, 384)
      end
    end
    context 'Invalid well position' do
      [0, -1, 385].each do |position|
        should "return nil for #{position}" do
          assert_nil Map.horizontal_to_vertical(position, 384)
        end
      end
    end
  end

  context 'Invalid plate_size' do
    [0, 1, -1, 95, 97, 383, 385].each do |plate_size|
      should "return nil for #{plate_size}" do
        assert_nil Map.horizontal_to_vertical(1, plate_size)
      end
    end
  end

  context 'The despcription for rows/colums' do
    should 'return the expected wells for 96 well plates' do
      assert_equal(%w(G1 G2 G3 G4 G5 G6 G7 G8 G9 G10 G11 G12), Map::Coordinate.descriptions_for_row('G', 96))
      assert_equal(%w(A5 B5 C5 D5 E5 F5 G5 H5), Map::Coordinate.descriptions_for_column(5, 96))
    end

    should 'return the expected wells for 384 well plates' do
      assert_equal(%w(G1 G2 G3 G4 G5 G6 G7 G8 G9 G10 G11 G12
                      G13 G14 G15 G16 G17 G18 G19 G20 G21 G22 G23 G24), Map::Coordinate.descriptions_for_row('G', 384))
      assert_equal(%w(A5 B5 C5 D5 E5 F5 G5 H5
                      I5 J5 K5 L5 M5 N5 O5 P5), Map::Coordinate.descriptions_for_column(5, 384))
    end
  end
end
