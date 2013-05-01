class AddIdentifiersToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :order_role_id, :integer
  end

  def self.down
    remove_column :orders, :order_role_id
  end
end
