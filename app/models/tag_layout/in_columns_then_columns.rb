# frozen_string_literal: true

# Lays out the tags so that they are column then column ordered.
# e.g. a dual index plate with 96 tags in tag group 1 and 4 in tag group 2 is laid out
# as follows for the first 4 rows/columns on a 384-well plate:
#     1     2     3     4   etc.
# ------------------------------
# A   1,1   1,3   9,1   9,3
# B   1,2   1,4   9,2   9,4
# C   2,1   2,3   10,1  10,3
# D   2,2   2,4   10,2  10,4
# etc.
# This version is a variation of the tag 2 order used in the InColumnsThenRows layout.
module TagLayout::InColumnsThenColumns
  def self.direction
    'column then column'
  end

  # We don't rely on well sorting, so lets not
  # worry about it.
  def self.well_order_scope
    :all
  end

  # Returns the tag index for the primary tag
  # That is the one laid out in columns with four copies of each (scale = 4).
  # The row and column are the indexes of the position, height and width are the plate dimensions.
  def self.tag_index(row, column, scale, height, _width)
    tag_col = (column / scale)
    tag_row = (row / scale)
    tag_row + (height / scale * tag_col)
  end

  # Returns the tag index for the secondary tag
  # e.g. 4 tags in group, A1 = 1, B1 = 2, A2 = 3, B2 = 4
  def self.tag2_index(row, column, scale, _height, _width)
    ((column % scale) * scale) + (row % scale)
  end
end
