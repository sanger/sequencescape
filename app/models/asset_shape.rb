# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class AssetShape < ActiveRecord::Base
  include SharedBehaviour::Named

  validates_presence_of :name, :horizontal_ratio, :vertical_ratio, :description_strategy
  validates_numericality_of :horizontal_ratio, :vertical_ratio

  def self.default_id
    AssetShape.find_by(name: 'Standard').id
  end

  def self.default
    AssetShape.find_by(name: 'Standard')
  end

  def standard?
    horizontal_ratio == 3 && vertical_ratio == 2
  end

  def multiplier(size)
    ((size / (vertical_ratio * horizontal_ratio))**0.5).to_i
  end
  private :multiplier

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

  def interlace(i, size)
    m, d = (i - 1).divmod(size / 2)
    2 * d + 1 + m
  end
  private :interlace

  def alternate_position(well_position, size, *dimensions)
    return nil unless Map.valid_well_position?(well_position)
    divisor, multiplier = dimensions.map { |n| send("plate_#{n}", size) }
    column, row = (well_position - 1).divmod(divisor)
    return nil unless (0...multiplier).cover?(column)
    return nil unless (0...divisor).cover?(row)
    alternate = (row * multiplier) + column + 1
  end
  private :alternate_position

  def location_from_row_and_column(row, column, size = 96)
    description_strategy.constantize.location_from_row_and_column(row, column, plate_width(size), size)
  end

  def location_from_index(index, size = 96)
    description_strategy.constantize.location_from_index(index, size)
  end

  def generate_map(size)
    raise StandardError, 'Map already exists' if Map.find_by(asset_size: size, asset_shape_id: id).present?
    ActiveRecord::Base.transaction do
      (0...size).each do |i|
        Map.create!(
          asset_size: size,
          asset_shape_id: id,
          location_id: i + 1,
          row_order: i,
          column_order: horizontal_to_vertical(i, size) || 0,
          description: location_from_index(i, size)
        )
      end
    end
  end
end
