class AddProductLineToRequestTypes < ActiveRecord::Migration
  def self.up
    add_column(:request_types, :product_line_id, :integer)
  end

  def self.down
    remove_column(:request_types, :product_line_id)
  end
end
