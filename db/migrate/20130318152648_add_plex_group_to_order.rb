class AddPlexGroupToOrder < ActiveRecord::Migration
  def self.up
    add_column :orders, :pre_cap_group, :integer
  end

  def self.down
   remove_column :orders, :pre_cap_group
  end
end
