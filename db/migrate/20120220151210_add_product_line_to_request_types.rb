class AddProductLineToRequestTypes < ActiveRecord::Migration
  def self.up
    add_column(:request_types, :product_line_id, :integer)
    add_column(:request_types, :deprecated, :boolean, :null => false, :default => false)
  end

  def self.down
    remove_column(:request_types, :product_line_id)
    remove_column(:request_types, :deprecated)
  end
end
