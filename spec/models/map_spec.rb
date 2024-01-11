# frozen_string_literal: true

require 'rails_helper'

describe Map, type: :model do
  context 'with Chromium Chip 16-well' do
    # The Map class contains a nested module called Coordinate. For clarity, we
    # use map_class to refer to the Map class and coordinate_module to refer to
    # the Coordinate module.
    #
    # The Chromium Chip 16-well has 16 wells arranged in 2 rows and 8 columns.
    # The following diagrams show the horizontal and vertical positions of the
    # wells used by the methods in Map and Map::Coordinate.
    #
    # horizontal positions (order in rows)
    #      1    2    3    4    5    6    7    8
    #    ╔════╦════╦════╦════╦════╦════╦════╦════╗
    #  A ║  1 ║  2 ║  3 ║  4 ║  5 ║  6 ║  7 ║  8 ║
    #    ║════╬════╬════╬════╬════╬════╬════╬════╣
    #  B ║  9 ║ 10 ║ 11 ║ 12 ║ 13 ║ 14 ║ 15 ║ 16 ║
    #    ╚════╩════╩════╩════╩════╩════╩════╩════╝

    # vertical positions (order in columns)
    #      1    2    3    4    5    6    7    8
    #    ╔════╦════╦════╦════╦════╦════╦════╦════╗
    #  A ║  1 ║  3 ║  5 ║  7 ║  9 ║ 11 ║ 13 ║ 15 ║
    #    ║════╬════╬════╬════╬════╬════╬════╬════╣
    #  B ║  2 ║  4 ║  6 ║  8 ║ 10 ║ 12 ║ 14 ║ 16 ║
    #    ╚════╩════╩════╩════╩════╩════╩════╩════╝

    let(:map_class) { described_class }
    let(:plate_size) { 16 } # Chromium Chip 16-well

    describe Map::Coordinate do
      let(:coordinate_module) { described_class }

      describe '.location_from_row_and_column' do
        it 'returns the name of a well by row and colum' do
          # Rows are using zero-based index; columns are using one-based index.
          (1..8).each do |column|
            expect(coordinate_module.location_from_row_and_column(0, column)).to eq("A#{column}")
            expect(coordinate_module.location_from_row_and_column(1, column)).to eq("B#{column}")
          end
        end
      end

      describe '.description_to_horizontal_plate_position' do
        it 'returns nil if well description is invalid' do
          expect(coordinate_module.description_to_horizontal_plate_position('', plate_size)).to be_nil
          expect(coordinate_module.description_to_horizontal_plate_position(nil, plate_size)).to be_nil
        end

        it 'returns nil if plate size is invalid' do
          expect(coordinate_module.description_to_horizontal_plate_position('A1', '16')).to be_nil # string
          expect(coordinate_module.description_to_horizontal_plate_position('A1', 0)).to be_nil # zero
          expect(coordinate_module.description_to_horizontal_plate_position('A1', -1)).to be_nil # negative
        end

        it 'returns one-based index of a well in rows' do
          # Indexes of wells in rows: 1 to 16 for A1, A2, A3, ..., A8, B1, B2, B3, ..., B8
          (1..8).each do |column|
            expect(coordinate_module.description_to_horizontal_plate_position("A#{column}", plate_size)).to eq(column)
            expect(coordinate_module.description_to_horizontal_plate_position("B#{column}", plate_size)).to eq(
              column + 8
            )
          end
        end
      end

      describe '.description_to_vertical_plate_position' do
        it 'returns nil if well description is invalid' do
          expect(coordinate_module.description_to_vertical_plate_position('A1', '16')).to be_nil # string
          expect(coordinate_module.description_to_vertical_plate_position('A1', 0)).to be_nil # zero
          expect(coordinate_module.description_to_vertical_plate_position('A1', -1)).to be_nil # negative
        end

        it 'returns nil if plate size is invalid' do
          expect(coordinate_module.description_to_vertical_plate_position('', plate_size)).to be_nil
          expect(coordinate_module.description_to_vertical_plate_position(nil, plate_size)).to be_nil
        end

        it 'returns one-based index of a well columns' do
          # Indexes of wells in columns: 1 to 16 for A1, B1, A2, B2, A3, B3, ..., A8, B8
          (1..8).each do |column|
            expect(coordinate_module.description_to_vertical_plate_position("A#{column}", plate_size)).to eq(
              (2 * column) - 1
            )
            expect(coordinate_module.description_to_vertical_plate_position("B#{column}", plate_size)).to eq(2 * column)
          end
        end
      end

      describe '.horizontal_plate_position_to_description' do
        it 'returns nil if well position is invalid' do
          expect(coordinate_module.horizontal_plate_position_to_description('1', plate_size)).to be_nil # string
          expect(coordinate_module.horizontal_plate_position_to_description(0, plate_size)).to be_nil # zero
          expect(coordinate_module.horizontal_plate_position_to_description(-1, plate_size)).to be_nil # negative
          expect(coordinate_module.horizontal_plate_position_to_description(17, plate_size)).to be_nil # out of bound
        end

        it 'returns nil if plate size is invalid' do
          expect(coordinate_module.horizontal_plate_position_to_description(1, '16')).to be_nil # string
          expect(coordinate_module.horizontal_plate_position_to_description(1, 0)).to be_nil # zero
          expect(coordinate_module.horizontal_plate_position_to_description(1, -1)).to be_nil # negative
        end

        it 'returns name of a well in rows by one-based index' do
          # Names of wells in rows: A1, A2, A3, ..., A8, B1, B2, B3, ..., B8 for indexes 1 to 16
          (1..8).each do |column|
            expect(coordinate_module.horizontal_plate_position_to_description(column, plate_size)).to eq("A#{column}")
            expect(coordinate_module.horizontal_plate_position_to_description(column + 8, plate_size)).to eq(
              "B#{column}"
            )
          end
        end
      end

      describe '.vertical_plate_position_to_description' do
        it 'returns nil if well position is invalid' do
          expect(coordinate_module.vertical_plate_position_to_description('1', plate_size)).to be_nil # string
          expect(coordinate_module.vertical_plate_position_to_description(0, plate_size)).to be_nil # zero
          expect(coordinate_module.vertical_plate_position_to_description(-1, plate_size)).to be_nil # negative
          expect(coordinate_module.vertical_plate_position_to_description(17, plate_size)).to be_nil # out of bound
        end

        it 'returns nil if plate size is invalid' do
          expect(coordinate_module.vertical_plate_position_to_description(1, '16')).to be_nil # string
          expect(coordinate_module.vertical_plate_position_to_description(1, 0)).to be_nil # zero
          expect(coordinate_module.vertical_plate_position_to_description(1, -1)).to be_nil # negative
        end

        it 'returns name of a well in columns by one-based index' do
          # Names of wells in columns: A1, B1, A2, B2, A3, B3, ..., A8, B8 for indexes 1 to 16
          (1..8).each do |column|
            expect(coordinate_module.vertical_plate_position_to_description((2 * column) - 1, plate_size)).to eq(
              "A#{column}"
            )
            expect(coordinate_module.vertical_plate_position_to_description(2 * column, plate_size)).to eq("B#{column}")
          end
        end
      end

      describe '.descriptions_for_row' do
        it 'returns names of wells in a row' do
          expect(coordinate_module.descriptions_for_row('A', plate_size)).to eq((1..8).map { |column| "A#{column}" })
          expect(coordinate_module.descriptions_for_row('B', plate_size)).to eq((1..8).map { |column| "B#{column}" })
        end
      end

      describe '.descriptions_for_column' do
        it 'returns names of wells in a column' do
          (1..8).each do |column|
            expect(coordinate_module.descriptions_for_column(column, plate_size)).to eq(["A#{column}", "B#{column}"])
          end
        end
      end

      describe '.plate_width' do
        it 'returns the width of a plate' do
          expect(coordinate_module.plate_width(plate_size)).to eq(8)
        end
      end

      describe '.plate_length' do
        it 'returns the height of a plate' do
          expect(coordinate_module.plate_length(plate_size)).to eq(2)
        end
      end

      describe '.vertical_position_to_description' do
        it 'returns the name of a well by well position and height' do
          # The well position is in column order. Instead of plate size, the
          # length (height, number of rows) of the plate is used to find the well.
          expect(coordinate_module.vertical_position_to_description(1, 2)).to eq('A1')
          expect(coordinate_module.vertical_position_to_description(2, 2)).to eq('B1')
          expect(coordinate_module.vertical_position_to_description(3, 2)).to eq('A2')

          # ...
          expect(coordinate_module.vertical_position_to_description(15, 2)).to eq('A8')
          expect(coordinate_module.vertical_position_to_description(16, 2)).to eq('B8')
        end
      end

      describe '.horizontal_position_to_description' do
        it 'returns the name of a well by well position and width' do
          # The well position is in row order. Instead of plate size, the width
          # (number of columns) of the plate is used to find the well.
          expect(coordinate_module.horizontal_position_to_description(1, 8)).to eq('A1')
          expect(coordinate_module.horizontal_position_to_description(2, 8)).to eq('A2')

          # ...
          expect(coordinate_module.horizontal_position_to_description(8, 8)).to eq('A8')
          expect(coordinate_module.horizontal_position_to_description(9, 8)).to eq('B1')

          # ...
          expect(coordinate_module.horizontal_position_to_description(15, 8)).to eq('B7')
          expect(coordinate_module.horizontal_position_to_description(16, 8)).to eq('B8')
        end
      end

      describe '.horizontal_to_vertical' do
        it 'returns the vertical position of a well by horizontal position' do
          input = (1..16).to_a
          expected = input.select(&:odd?) + input.select(&:even?)

          input
            .zip(expected)
            .each do |horizontal, vertical|
              expect(coordinate_module.horizontal_to_vertical(horizontal, plate_size)).to eq(vertical)
            end
        end
      end

      describe '.vertical_to_horizontal' do
        it 'returns the horizontal position of a well by vertical position' do
          expected = (1..16).to_a
          input = expected.select(&:odd?) + expected.select(&:even?)

          input
            .zip(expected)
            .each do |vertical, horizontal|
              expect(coordinate_module.vertical_to_horizontal(vertical, plate_size)).to eq(horizontal)
            end
        end
      end

      describe '.location_from_index' do
        it 'returns the name of a well by zero-based index in row order' do
          # Names of wells in rows: A1, A2, A3, ..., A8, B1, B2, B3, ..., B8 for indexes 0 to 15
          8.times do |index|
            expect(coordinate_module.location_from_index(index, plate_size)).to eq("A#{index + 1}") # first row
            expect(coordinate_module.location_from_index(index + 8, plate_size)).to eq("B#{index + 1}") # second row
          end
        end
      end
    end

    describe 'class methods' do
      describe '.valid_plate_size?' do
        # This method checks if the plate size is a positive integer only.
        it 'returns true for a valid plate size' do
          expect(map_class.valid_plate_size?(plate_size)).to be true
        end

        it 'returns false for an invalid plate size' do
          expect(map_class.valid_plate_size?('16')).to be false # string
          expect(map_class.valid_plate_size?(0)).to be false # zero
          expect(map_class.valid_plate_size?(-1)).to be false # negative
        end
      end

      describe '.valid_plate_position_and_plate_size?' do
        # This method is able to check if the position is out of bounds.
        it 'returns true for a valid plate position and plate size' do
          expect(map_class.valid_plate_position_and_plate_size?(1, plate_size)).to be true
          expect(map_class.valid_plate_position_and_plate_size?(16, plate_size)).to be true
        end

        it 'returns false for an invalid plate position' do
          expect(map_class.valid_plate_position_and_plate_size?(0, plate_size)).to be false # zero
          expect(map_class.valid_plate_position_and_plate_size?(17, plate_size)).to be false # out of bound
        end

        it 'returns false for an invalid plate size' do
          expect(map_class.valid_plate_position_and_plate_size?(1, 0)).to be false
        end
      end

      describe '.valid_well_description_and_plate_size?' do
        # This method is not able to check if the well is out of bounds.
        # It is called by Coordinate methods for basic validation.
        it 'returns true for a valid well description and plate size' do
          expect(map_class.valid_well_description_and_plate_size?('A1', plate_size)).to be true
        end

        it 'returns false if well description is invalid' do
          expect(map_class.valid_well_description_and_plate_size?('', plate_size)).to be false # empty string
          expect(map_class.valid_well_description_and_plate_size?(nil, plate_size)).to be false # nil
        end

        it 'returns false if plate size is invalid' do
          expect(map_class.valid_well_description_and_plate_size?('A1', '16')).to be false # string
          expect(map_class.valid_well_description_and_plate_size?('A1', 0)).to be false # zero
          expect(map_class.valid_well_description_and_plate_size?('A1', -1)).to be false # negative
        end
      end

      describe '.valid_well_position?' do
        # This method checks if the well position is a positive integer only.
        it 'returns true for a valid well position' do
          expect(map_class.valid_well_position?(1)).to be true
          expect(map_class.valid_well_position?(16)).to be true
        end

        it 'returns false of an invalid well position' do
          expect(map_class.valid_well_position?('1')).to be false # string
          expect(map_class.valid_well_position?(0)).to be false # zero
          expect(map_class.valid_well_position?(nil)).to be false # string
        end
      end

      describe '.location_from_row_and_column' do
        # This method calls Map::Coordinate.location_from_row_and_column .
        it 'returns the name of a well by row and colum' do
          # Rows are using zero-based index; columns are using one-based index.
          (1..8).each do |column|
            expect(map_class.location_from_row_and_column(0, column)).to eq("A#{column}")
            expect(map_class.location_from_row_and_column(1, column)).to eq("B#{column}")
          end
        end
      end

      describe '.horizontal_to_vertical' do
        # This method calls Map::Coordinate.horizontal_to_vertical .
        it 'returns the vertical position of a well by horizontal position' do
          input = (1..16).to_a
          expected = input.select(&:odd?) + input.select(&:even?)

          input
            .zip(expected)
            .each do |horizontal, vertical|
              expect(map_class.horizontal_to_vertical(horizontal, plate_size)).to eq(vertical)
            end
        end
      end

      describe '.vertical_to_horizontal' do
        # This method calls Map::Coordinate.vertical_to_horizontal .
        it 'returns the vertical position of a well by horizontal position' do
          expected = (1..16).to_a
          input = expected.select(&:odd?) + expected.select(&:even?)

          input
            .zip(expected)
            .each do |vertical, horizontal|
              expect(map_class.vertical_to_horizontal(vertical, plate_size)).to eq(horizontal)
            end
        end
      end

      describe '.split_well_description' do
        it 'returns the row and column of a well in a hash' do
          # Rows are using zero-based index; columns are using one-based index.
          expect(map_class.split_well_description('A1')).to eq({ row: 0, col: 1 })
          expect(map_class.split_well_description('A8')).to eq({ row: 0, col: 8 })
          expect(map_class.split_well_description('B1')).to eq({ row: 1, col: 1 })
          expect(map_class.split_well_description('B8')).to eq({ row: 1, col: 8 })
        end
      end

      describe '.strip_description' do
        # Removes the leading zero from column if there is one.
        it 'returns well description by removing the leading zero from column' do
          expect(map_class.strip_description('A01')).to eq('A1') # one leading zero
          expect(map_class.strip_description('B1')).to eq('B1') # no leading zeros
        end
      end

      describe '.pad_description' do
        # Returns well description with a leading zero for a given map.
        # AssetShapes and Maps are created before the test suite runs and
        # they are available in the test database.
        let(:chromium_chip_maps) { map_class.joins(:asset_shape).where(asset_shapes: { name: 'ChromiumChip' }) }

        it 'returns well description by adding a leading zero' do
          expect(map_class.pad_description(chromium_chip_maps.first)).to eq('A01')
          expect(map_class.pad_description(chromium_chip_maps.last)).to eq('B08')
        end
      end

      describe 'walk_plate_in_column_major_order' do
        let(:shape) { AssetShape.find_by(name: 'ChromiumChip') }

        it 'walks vertically' do
          # Generate a hash of well descriptions and their column order (zero-based) for testing.
          hash = {}
          map_class.walk_plate_vertically(plate_size, shape.id) do |map, column_order|
            hash[map.description] = column_order
          end
          expected =
            {
              A1: 0,
              B1: 1,
              A2: 2,
              B2: 3,
              A3: 4,
              B3: 5,
              A4: 6,
              B4: 7,
              A5: 8,
              B5: 9,
              A6: 10,
              B6: 11,
              A7: 12,
              B7: 13,
              A8: 14,
              B8: 15
            }.transform_keys(&:to_s)
          expect(hash).to eq(expected)
        end

        it 'walks horizontally' do
          # Generate a hash of well descriptions and their column order (zero-based) for testing.
          hash = {}
          map_class.walk_plate_horizontally(plate_size, shape.id) { |map, row_order| hash[map.description] = row_order }
          expected =
            {
              A1: 0,
              A2: 1,
              A3: 2,
              A4: 3,
              A5: 4,
              A6: 5,
              A7: 6,
              A8: 7,
              B1: 8,
              B2: 9,
              B3: 10,
              B4: 11,
              B5: 12,
              B6: 13,
              B7: 14,
              B8: 15
            }.transform_keys(&:to_s)
          expect(hash).to eq(expected)
        end
      end
    end
  end
end
