# frozen_string_literal: true

# Lays out the tags so that they are row ordered.
module TagLayout::CombInRows
  def self.direction
    'combinatorial in rows'
  end

  def self.well_order_scope
    :in_row_major_order
  end

  def self.tag_index(row, _column, _scale, _height, _width)
    row
  end

  def self.tag2_index(_row, column, _scale, _height, _width)
    column
  end
end
