# frozen_string_literal: true
# Map identifies a {Well wells} position on a {Plate}. It is not related to
# the ruby #map method.
class Map < ApplicationRecord
  validates :description, :asset_size, :location_id, :row_order, :column_order, :asset_shape, presence: true
  validates :asset_size, :row_order, :column_order, numericality: true

  # @!attribute description
  #   @return [String] the name of the well. In most cases this will be in the
  #                    along the lines of A1 or H12
  # @!attribute asset_size
  #   @return [Integer] the plate size for which the {Map} corresponds
  # @!attribute row_order
  #   @return [Integer] zero indexed order of the well when sorted by row
  # @!attribute column_order
  #   @return [Integer] zero indexed order of the well when sorted by column
  module Coordinate
    # TODO: These methods are only valid for standard plates. Moved them here to make that more explicit
    # (even if its not strictly appropriate) They could do with refactoring/removing.

    # A hash representing the dimensions of different types of plates.
    # The keys are the total number of wells in the plate, and the values are
    # arrays, where the first element is the number of columns and the second
    # element is the number of rows.
    #
    # @note
    #   - 96 represents a 96-well plate, arranged in 12 columns and 8 rows.
    #   - 384 represents a 384-well plate, arranged in 24 columns and 16 rows.
    #   - 16 represents a 16-well Chromium Chip, which has 8 columns and 2 rows.
    #     Although a 16-well Chromium Chip does not have 3:2 ratio to be a
    #     standard plate, i.e. it has 4:1 ratio, the methods here still apply.
    #     Note that the asset shape is a generic one, Shape4x1, although it has
    #     been created for the 16-well Chromium Chip.
    #   - 8 represents a 8-well Chromium Chip, which has 8 columns and 1 row.
    #     Note that the asset shape is a generic one, Shape8x1, although it has
    #     been created for the 8-well Chromium Chip.
    # @return [Hash{Integer => Array<Integer>}] the dimensions of the plates
    PLATE_DIMENSIONS = Hash.new { |_h, _k| [] }.merge(96 => [12, 8], 384 => [24, 16], 16 => [8, 2], 8 => [8, 1])

    # Seems to expect row to be zero-indexed but column to be 1 indexed
    def self.location_from_row_and_column(row, column, _ = nil, __ = nil)
      "#{('A'.getbyte(0) + row).chr}#{column}"
    end

    def self.description_to_horizontal_plate_position(well_description, plate_size)
      return nil unless Map.valid_well_description_and_plate_size?(well_description, plate_size)

      split_well = Map.split_well_description(well_description)
      width = plate_width(plate_size)
      return nil if width.nil?

      (width * split_well[:row]) + split_well[:col]
    end

    def self.description_to_vertical_plate_position(well_description, plate_size)
      return nil unless Map.valid_well_description_and_plate_size?(well_description, plate_size)

      split_well = Map.split_well_description(well_description)
      length = plate_length(plate_size)
      return nil if length.nil?

      (length * (split_well[:col] - 1)) + split_well[:row] + 1
    end

    def self.horizontal_plate_position_to_description(well_position, plate_size)
      return nil unless Map.valid_plate_position_and_plate_size?(well_position, plate_size)

      width = plate_width(plate_size)
      return nil if width.nil?

      horizontal_position_to_description(well_position, width)
    end

    def self.vertical_plate_position_to_description(well_position, plate_size)
      return nil unless Map.valid_plate_position_and_plate_size?(well_position, plate_size)

      length = plate_length(plate_size)
      return nil if length.nil?

      vertical_position_to_description(well_position, length)
    end

    def self.descriptions_for_row(row, size)
      (1..plate_width(size)).map { |column| "#{row}#{column}" }
    end

    def self.descriptions_for_column(column, size)
      (0...plate_length(size)).map { |row| Map.location_from_row_and_column(row, column) }
    end

    def self.plate_width(plate_size)
      PLATE_DIMENSIONS[plate_size].first
    end

    def self.plate_length(plate_size)
      PLATE_DIMENSIONS[plate_size].last
    end

    # well number counting by columns, length is the number of rows in the plate
    # e.g. B5 sends this 34 and 8
    def self.vertical_position_to_description(well_position, length)
      desc_letter = (((well_position - 1) % length) + 65).chr
      desc_number = ((well_position - 1) / length) + 1
      (desc_letter + desc_number.to_s)
    end

    def self.horizontal_position_to_description(well_position, width)
      desc_letter = (((well_position - 1) / width) + 65).chr
      desc_number = ((well_position - 1) % width) + 1
      (desc_letter + desc_number.to_s)
    end

    def self.horizontal_to_vertical(well_position, plate_size)
      alternate_position(well_position, plate_size, :width, :length)
    end

    def self.vertical_to_horizontal(well_position, plate_size)
      alternate_position(well_position, plate_size, :length, :width)
    end

    def self.location_from_index(index, size)
      horizontal_plate_position_to_description(index + 1, size)
    end

    class << self
      # Given the well position described in terms of a direction (vertical or horizontal) this function
      # will map it to the alternate positional representation, i.e. a vertical position will be mapped
      # to a horizontal one.  It does this with the divisor and multiplier, which will be reversed for
      # the alternate.
      #
      # NOTE: I don't like this, it just makes things clearer than it was!
      # NOTE: I hate the nil returns but external code would take too long to change this time round
      def alternate_position(well_position, size, *dimensions)
        return nil unless Map.valid_well_position?(well_position)

        divisor, multiplier = dimensions.map { |n| send(:"plate_#{n}", size) }
        return nil if divisor.nil? || multiplier.nil?

        column, row = (well_position - 1).divmod(divisor)
        return nil unless (0...multiplier).cover?(column)
        return nil unless (0...divisor).cover?(row)

        (row * multiplier) + column + 1
      end
      private :alternate_position
    end
  end

  module Sequential
    def self.location_from_row_and_column(row, column, width, size)
      digit_count = Math.log10(size + 1).ceil
      "S%0#{digit_count}d" % [(row * width) + column]
    end

    def self.location_from_index(index, size)
      digit_count = Math.log10(size + 1).ceil
      "S%0#{digit_count}d" % [index + 1]
    end
  end

  scope :for_position_on_plate,
        ->(position, plate_size, asset_shape) do
          where(row_order: position - 1, asset_size: plate_size, asset_shape_id: asset_shape.id)
        end

  scope :where_description, ->(*descriptions) { where(description: descriptions.flatten) }
  scope :where_plate_size, ->(size) { where(asset_size: size) }
  scope :where_plate_shape, ->(asset_shape) { where(asset_shape_id: asset_shape) }
  scope :where_vertical_plate_position, ->(*positions) { where(column_order: positions.map { |v| v - 1 }) }
  scope :for_plate, ->(plate) { where_plate_size(plate.size).where_plate_shape(plate.asset_shape) }

  belongs_to :asset_shape, class_name: 'AssetShape'
  delegate :standard?, to: :asset_shape

  def self.valid_plate_size?(plate_size)
    plate_size.is_a?(Integer) && plate_size > 0
  end

  def self.valid_plate_position_and_plate_size?(well_position, plate_size)
    return false unless valid_well_position?(well_position)
    return false unless valid_plate_size?(plate_size)
    return false if well_position > plate_size

    true
  end

  def self.valid_well_description_and_plate_size?(well_description, plate_size)
    return false if well_description.blank?
    return false unless valid_plate_size?(plate_size)

    true
  end

  def self.valid_well_position?(well_position)
    well_position.is_a?(Integer) && well_position > 0
  end

  def vertical_plate_position
    column_order + 1
  end

  def height
    asset_shape.plate_height(asset_size)
  end

  def width
    asset_shape.plate_width(asset_size)
  end

  ##
  # Column of particular map location. Zero indexed integer
  def column
    row_order % width
  end

  ##
  # Row of particular map location. Zero indexed integer
  def row
    column_order % height
  end

  def horizontal_plate_position
    row_order + 1
  end

  def snp_id
    raise StandardError, 'Only standard maps can be converted to SNP' unless map.standard?

    horizontal_plate_position
  end

  def self.location_from_row_and_column(row, column)
    "#{('A'.getbyte(0) + row).chr}#{column}"
  end

  def self.horizontal_to_vertical(well_position, plate_size, _plate_shape = nil)
    Map::Coordinate.horizontal_to_vertical(well_position, plate_size)
  end

  def self.vertical_to_horizontal(well_position, plate_size, _plate_shape = nil)
    Map::Coordinate.vertical_to_horizontal(well_position, plate_size)
  end

  def self.map_96wells
    Map.where(asset_size: 96)
  end

  def self.map_384wells
    Map.where(asset_size: 384)
  end

  def self.split_well_description(well_description)
    { row: well_description.getbyte(0) - 65, col: well_description[1, well_description.size].to_i }
  end

  # Stip any leading zeros from the well name
  # eg. A01 => A1
  def self.strip_description(description)
    description.sub(/0(\d)$/, '\1')
  end

  def self.pad_description(map)
    split_description = split_well_description(map.description)
    return "#{map.description[0].chr}0#{split_description[:col]}" if split_description[:col] < 10

    map.description
  end

  scope :in_row_major_order, -> { order(:row_order) }
  scope :in_reverse_row_major_order, -> { order(row_order: :desc) }
  scope :in_column_major_order, -> { order(:column_order) }
  scope :in_reverse_column_major_order, -> { order(column_order: :desc) }

  class << self
    # Walking in column major order goes by the columns: A1, B1, C1, ... A2, B2, ...
    def walk_plate_in_column_major_order(size, asset_shape = nil)
      asset_shape ||= AssetShape.default_id
      where(asset_size: size, asset_shape_id: asset_shape)
        .order(:column_order)
        .each { |position| yield(position, position.column_order) }
    end
    alias walk_plate_vertically walk_plate_in_column_major_order

    # Walking in row major order goes by the rows: A1, A2, A3, ... B1, B2, B3 ....
    def walk_plate_in_row_major_order(size, asset_shape = nil)
      asset_shape ||= AssetShape.default_id
      where(asset_size: size, asset_shape_id: asset_shape)
        .order(:row_order)
        .each { |position| yield(position, position.row_order) }
    end
    alias walk_plate_horizontally walk_plate_in_row_major_order
  end
end
