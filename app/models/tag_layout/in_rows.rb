# frozen_string_literal: true
# Lays out the tags so that they are row ordered.
module TagLayout::InRows
  def self.direction
    'row'
  end

  def self.well_order_scope
    :in_row_major_order
  end

  # Returns the tag index for the primary tag
  # That is the one laid out in rows with four copies of each
  def self.tag_index(row, column, scale, _height, width)
    tag_col = (column / scale)
    tag_row = (row / scale)
    tag_col + (width / scale * tag_row)
  end

  def self.tag2_index(row, column, scale, height, width)
    tag_index(row, column, scale, height, width)
  end
end
