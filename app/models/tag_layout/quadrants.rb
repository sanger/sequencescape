# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

# Tags are arranged in quadrants in the case of some 384 well plates.
# Essentially a 96 well plate of tags is transferred onto the same target
# plate four times, such that each cluster of 4 wells contains the same tag.
# Ie. Tag 1 is in wells A1, B1, A2, B2
# Four different tag 2s then get applied to each cluster. These tags are
# laid out in *ROW* order
# ie. A1 => 1, A2 => 2, B1 => 3, B2 => 4
class TagLayout::Quadrants < TagLayout::Walker
  # Each row and column is essentially duplicated. So our scale
  # is 2 (not four)
  PLATE_SCALE = 2
  self.walking_by = 'quadrants'

  def walk_wells
    wells_in_walking_order.includes(:map).each do |well|
      row = well.map.row
      col = well.map.column
      index = direction_helper.primary_index(row, col, PLATE_SCALE, height)
      index2 = direction_helper.secondary_index(row, col, PLATE_SCALE)
      yield(well, index, index2)
    end
  end

  private

  def height
    @height ||= plate.height
  end

  def width
    @width ||= plate.wdith
  end

  def direction_helper
    tag_layout.direction_algorithm_module
  end
end
