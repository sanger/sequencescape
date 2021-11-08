# frozen_string_literal: true
# Describes the shape of the plate and its numbering system.
# The majority of our {Plate plates} have a 3:2 width height ratio:
# eg. 12*8 or 24*16
# And wells are numbered by 'coordinate' eg. A1, H12
# However FluidigmPlates have different dimensions:
# - 6 * 16 (96)
# - 12 * 16 (192)
# In addition, wells are labeled sequentially in column order, padded with zeros:
# eg. S01-S96 and S001-S192
class AssetShape < ApplicationRecord
  include SharedBehaviour::Named

  validates :name, :horizontal_ratio, :vertical_ratio, :description_strategy, presence: true
  validates :horizontal_ratio, :vertical_ratio, numericality: true

  def self.default_id
    @default_id ||= default.id
  end

  def self.default
    AssetShape
      .create_with(horizontal_ratio: 3, vertical_ratio: 2, description_strategy: 'Map::Coordinate')
      .find_or_create_by(name: 'Standard')
  end

  def standard?
    horizontal_ratio == 3 && vertical_ratio == 2
  end

  def plate_height(size)
    multiplier(size) * vertical_ratio
  end

  def plate_width(size)
    multiplier(size) * horizontal_ratio
  end

  def horizontal_to_vertical(well_position, plate_size)
    alternate_position(well_position, plate_size, :width, :height)
  end

  def vertical_to_horizontal(well_position, plate_size)
    alternate_position(well_position, plate_size, :height, :width)
  end

  def interlaced_vertical_to_horizontal(well_position, plate_size)
    alternate_position(interlace(well_position, plate_size), plate_size, :height, :width)
  end

  def vertical_to_interlaced_vertical(well_position, plate_size)
    interlace(well_position, plate_size)
  end

  def generate_map(size)
    raise StandardError, 'Map already exists' if Map.find_by(asset_size: size, asset_shape_id: id).present?

    ActiveRecord::Base.transaction do
      map_data =
        Array.new(size) do |i|
          {
            asset_size: size,
            asset_shape_id: id,
            location_id: i + 1,
            row_order: i,
            column_order: (horizontal_to_vertical(i + 1, size) || 1) - 1,
            description: location_from_index(i, size)
          }
        end
      Map.import(map_data)
    end
  end

  def alternate_position(well_position, size, *dimensions)
    return nil unless Map.valid_well_position?(well_position)

    divisor, multiplier = dimensions.map { |n| send("plate_#{n}", size) }
    column, row = (well_position - 1).divmod(divisor)
    return nil unless (0...multiplier).cover?(column)
    return nil unless (0...divisor).cover?(row)

    alternate = (row * multiplier) + column + 1
  end

  def location_from_row_and_column(row, column, size = 96)
    description_strategy.constantize.location_from_row_and_column(row, column, plate_width(size), size)
  end

  private

  def multiplier(size)
    ((size / (vertical_ratio * horizontal_ratio))**0.5).to_i
  end

  def interlace(i, size)
    m, d = (i - 1).divmod(size / 2)
    (2 * d) + 1 + m
  end

  def location_from_index(index, size = 96)
    description_strategy.constantize.location_from_index(index, size)
  end
end
