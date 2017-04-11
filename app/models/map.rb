# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

class Map < ActiveRecord::Base
  validates_presence_of :description, :asset_size, :location_id, :row_order, :column_order, :asset_shape
  validates_numericality_of :asset_size, :row_order, :column_order

  module Coordinate
    # TODO: These methods are only valid for standard plates. Moved them here to make that more explicit
    # (even if its not strictly appropriate) They could do with refactoring/removing.

    PLATE_DIMENSIONS = Hash.new { |_h, _k| [] }.merge(
      96  => [12, 8],
      384 => [24, 16]
    )

    def self.location_from_row_and_column(row, column, _ = nil, __ = nil)
      "#{(?A.getbyte(0) + row).chr}#{column}"
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

    def self.vertical_position_to_description(well_position, length)
      desc_letter = (((well_position - 1) % length) + 65).chr
      desc_number = ((well_position - 1) / length) + 1
      (desc_letter + (desc_number.to_s))
    end

    def self.horizontal_position_to_description(well_position, width)
      desc_letter = (((well_position - 1) / width) + 65).chr
      desc_number = ((well_position - 1) % width) + 1
      (desc_letter + (desc_number.to_s))
    end

    def self.horizontal_to_vertical(well_position, plate_size)
      alternate_position(well_position, plate_size, :width, :length)
    end

    def self.vertical_to_horizontal(well_position, plate_size)
      alternate_position(well_position, plate_size, :length, :width)
    end

    def self.location_from_index(index, size)
      horizontal_plate_position_to_description(index - 1, size)
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
      divisor, multiplier = dimensions.map { |n| send("plate_#{n}", size) }
      return nil if divisor.nil? or multiplier.nil?
      column, row = (well_position - 1).divmod(divisor)
      return nil unless (0...multiplier).cover?(column)
      return nil unless (0...divisor).cover?(row)
      alternate = (row * multiplier) + column + 1
    end
    private :alternate_position
  end
  end

  module Sequential
    def self.location_from_row_and_column(row, column, width, size)
      digit_count = Math.log10(size + 1).ceil
      "S%0#{digit_count}d" % [(row) * width + column]
    end

    def self.location_from_index(index, size)
      digit_count = Math.log10(size + 1).ceil
      "S%0#{digit_count}d" % [index + 1]
    end
  end

 scope :for_position_on_plate, ->(position, plate_size, asset_shape) {
    where(
        row_order: position - 1,
        asset_size: plate_size,
        asset_shape_id: asset_shape.id
    )
                               }

  scope :where_description, ->(*descriptions) { where(description: descriptions.flatten) }
  scope :where_plate_size,  ->(size) { where(asset_size: size) }
  scope :where_plate_shape, ->(asset_shape) { where(asset_shape_id: asset_shape) }
  scope :where_vertical_plate_position, ->(*positions) { where(column_order: positions.map { |v| v - 1 }) }

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

  def self.next_map_position(current_map_id)
    Map.find(current_map_id).next_map_position
  end

  def next_map_position
    Map.find_by(
      asset_size: asset_size,
      asset_shape_id: asset_shape_id,
      row_order: row_order + 1
    )
  end

  def self.horizontal_to_vertical(well_position, plate_size, _plate_shape = nil)
    Map::Coordinate.horizontal_to_vertical(well_position, plate_size)
  end

  def self.vertical_to_horizontal(well_position, plate_size, _plate_shape = nil)
    Map::Coordinate.vertical_to_horizontal(well_position, plate_size)
  end

  def self.next_vertical_map_position(current_map_id)
    Map.find(current_map_id).next_vertical_map_position
  end

  def next_vertical_map_position
    Map.find_by(
      asset_size: asset_size,
      asset_shape_id: asset_shape_id,
      column_order: column_order + 1
    )
  end

  def self.map_96wells
    Map.where(asset_size: 96)
  end

  def self.map_384wells
    Map.where(asset_size: 384)
  end

  def self.snp_map_id_to_pipelines_map_id(snp_map_id, plate_size)
    # We're only going to be getting standard plates in through SNP
    Map.where(
      asset_size: plate_size,
      row_order: snp_map_id.to_i + 1,
      asset_shape: AssetShape.default_id
    ).pluck(:id).first
  end

  def self.pipelines_map_id_to_snp_map_id(pipelines_map_id)
    # We're only going to be getting standard plates in through SNP
    Map.find(pipelines_map_id).snp_id
  end

  def self.split_well_description(well_description)
    { row: well_description.getbyte(0) - 65, col: well_description[1, well_description.size].to_i }
  end

  def self.find_for_cell_location(cell_location, asset_size)
    find_by(description: cell_location.sub(/0(\d)$/, '\1'), asset_size: asset_size)
  end

  def self.pad_description(map)
    split_description = split_well_description(map.description)
    return "#{map.description[0].chr}0#{split_description[:col]}" if split_description[:col] < 10

    map.description
  end

   scope :in_row_major_order,            -> { order('row_order ASC') }
   scope :in_reverse_row_major_order,    -> { order('row_order DESC') }
   scope :in_column_major_order,         -> { order('column_order ASC') }
   scope :in_reverse_column_major_order, -> { order('column_order DESC') }

  class << self
    # Caution! Only use for seeds. Not valid elsewhere
    def plate_dimensions(plate_size)
      case plate_size
      when 96  then yield(12, 8)
      when 384 then yield(24, 16)
      else raise StandardError, "Cannot determine plate dimensions for #{plate_size}"
      end
    end

    # Walking in column major order goes by the columns: A1, B1, C1, ... A2, B2, ...
    def walk_plate_in_column_major_order(size, asset_shape = nil)
      asset_shape ||= AssetShape.default_id
      where(asset_size: size, asset_shape_id: asset_shape).order(:column_order).each do |position|
        yield(position, position.column_order)
      end
    end
    alias_method(:walk_plate_vertically, :walk_plate_in_column_major_order)

    # Walking in row major order goes by the rows: A1, A2, A3, ... B1, B2, B3 ....
    def walk_plate_in_row_major_order(size, asset_shape = nil)
      asset_shape ||= AssetShape.default_id
      where(asset_size: size, asset_shape_id: asset_shape).order(:row_order).each do |position|
        yield(position, position.row_order)
      end
    end
  end
end
