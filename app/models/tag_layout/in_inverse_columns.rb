# frozen_string_literal: true
# Lays out the tags so that they are inverse column ordered.
module TagLayout::InInverseColumns
  def self.direction
    'inverse column'
  end

  def self.well_order_scope
    :in_inverse_column_major_order
  end

  # Returns the tag index for the primary tag
  # That is the one laid out in columns with four copies of each
  def self.tag_index(row, column, scale, height, width)
    tag_col = (column / scale)
    tag_row = (row / scale)
    ((height / scale) * (width / scale)) - (tag_row + (height / scale * tag_col)) - 1
  end

  def self.tag2_index(row, column, scale, height, width)
    tag_index(row, column, scale, height, width)
  end
end
