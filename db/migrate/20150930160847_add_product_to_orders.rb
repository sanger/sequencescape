
class AddProductToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :product_id, :integer
  end

  def self.down
    remove_column :orders, :product_id
  end
end
