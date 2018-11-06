# Lays out the tags so that they are column ordered.
module TagLayout::InColumns
  def self.direction
    'column'
  end

  def self.well_order_scope
    :in_column_major_order
  end
end
