class AddIdentifiersTable < ActiveRecord::Migration
  def self.up
    create_table :order_roles do |t|
      t.string :role
      t.timestamps
    end
  end

  def self.down
    drop_table :order_roles
  end
end
