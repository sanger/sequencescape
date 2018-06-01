
# Lays out the tags so that they are inverse column ordered.
module TagLayout::InInverseColumns
  def self.direction
    'inverse column'
  end

  def self.well_order_scope
    :in_inverse_column_major_order
  end
end
