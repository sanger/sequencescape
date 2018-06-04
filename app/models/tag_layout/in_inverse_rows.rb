
# Lays out the tags so that they are inverse row ordered.
module TagLayout::InInverseRows
  def self.direction
    'inverse row'
  end

  def self.well_order_scope
    :in_inverse_row_major_order
  end
end
