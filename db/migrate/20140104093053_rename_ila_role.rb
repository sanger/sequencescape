class RenameIlaRole < ActiveRecord::Migration
  def self.up
    Order::OrderRole.find_by_role('ILA').update_attributes!(:role=>'ILA WGS')
  end

  def self.down
    Order::OrderRole.find_by_role('ILA WGS').update_attributes!(:role=>'ILA')
  end
end
