# Lays out the tags so that they are row ordered.
module TagLayout::InRows
  def self.direction
    'row'
  end

  def self.well_order_scope
    :in_row_major_order
  end
end
