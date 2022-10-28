# frozen_string_literal: true

# Lays out the tags so that they are column then row ordered.
# This version has a variation of the tag 2 order.
module TagLayout::InColumnsThenRowsAlternate
  def self.direction
    'column then row alternate'
  end

  # We don't rely on well sorting, so lets not
  # worry about it.
  def self.well_order_scope
    :all
  end

  # Returns the tag index for the primary tag
  # That is the one laid out in columns with four copies of each
  def self.tag_index(row, column, scale, height, _width)
    tag_col = (column / scale)
    tag_row = (row / scale)
    tag_row + (height / scale * tag_col)
  end

  # Returns the tag index for the secondary tag
  # e.g. 4 tags in group, A1 = 1, B1 = 2, A2 = 3, B2 = 4
  # This is the alternate arrangement
  def self.tag2_index(row, column, scale, _height, _width)
    (column % scale) * scale + (row % scale)
  end
end
