# frozen_string_literal: true
# Lays out the tags so that they are column ordered.
module TagLayout::InColumns
  def self.direction
    'column'
  end

  def self.well_order_scope
    :in_column_major_order
  end

  # Returns the tag index for the primary tag
  # That is the one laid out in columns with four copies of each
  def self.tag_index(row, column, scale, height, _width)
    tag_col = (column / scale)
    tag_row = (row / scale)
    tag_row + (height / scale * tag_col)
  end

  def self.tag2_index(row, column, scale, height, width)
    tag_index(row, column, scale, height, width)
  end
end
