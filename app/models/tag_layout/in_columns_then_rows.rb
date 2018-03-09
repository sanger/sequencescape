# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.

# Lays out the tags so that they are column ordered.
module TagLayout::InColumnsThenRows
  def self.direction
    'column then row'
  end

  # We don't rely on well sorting, so lets not
  # worry about it.
  def self.well_order_scope
    :all
  end

  # Returns the tag index for the primary tag
  # That is the one laid out in columns with four copies of each
  def self.primary_index(row, column, scale, height)
    tag_col = (column / scale)
    tag_row = (row / scale)
    tag_row + (height / scale * tag_col)
  end

  def self.secondary_index(row, column, scale)
    column % scale + (row % scale) * scale
  end
end
