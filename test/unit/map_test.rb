# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

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
      { 0 => nil, -1 => nil, 97 => nil, 384 => nil, '1' => nil }.each do |position, result|
        should "return nil for #{position.inspect}" do
          assert_equal result, Map.horizontal_to_vertical(position, 96)
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
      { 0 => nil, -1 => nil, 385 => nil }.each do |position, result|
        should "return nil for #{position}" do
          assert_equal result, Map.horizontal_to_vertical(position, 384)
        end
      end
    end
  end

  context 'Invalid plate_size' do
    { 0 => nil, 1 => nil, -1 => nil, 95 => nil, 97 => nil, 383 => nil, 385 => nil }.each do |plate_size, result|
      should "return nil for #{plate_size}" do
        assert_equal result, Map.horizontal_to_vertical(1, plate_size)
      end
    end
  end

  context '#next_map_position' do
    [['A1', 'A2', 96], ['A12', 'B1', 96], ['G9', 'G10', 96], ['H11', 'H12', 96], ['A1', 'A2', 384], ['A24', 'B1', 384], ['P23', 'P24', 384]].each do |current_map, expected_output, plate_size|
      should "return the correct next map position of #{current_map} to #{expected_output} for plate size #{plate_size}" do
        returned_map = Map.next_map_position(Map.find_by(description: current_map, asset_size: plate_size).id)
        assert_equal expected_output, returned_map.description
      end
    end

    [['H12', nil, 96], ['P24', nil, 384]].each do |current_map, expected_output, plate_size|
      should "return nil for end of plate for #{current_map}" do
        returned_map = Map.next_map_position(Map.find_by(description: current_map, asset_size: plate_size).id)
        assert_equal expected_output, returned_map
      end
    end
  end

  context '#find_for_cell_location' do
    should 'remove leading zero from cell location' do
      assert_equal Map.find_by(description: 'A1', asset_size: 96), Map.find_for_cell_location('A01', 96)
    end

    should 'not remove any non-leading zeroes' do
      assert_equal Map.find_by(description: 'A10', asset_size: 96), Map.find_for_cell_location('A10', 96)
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
