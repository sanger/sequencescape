# 2012012716103605_orders_fix_foreign_keys.rb

class OrdersFixForeignKeys < ActiveRecord::Migration
  def self.up
  	#execute "UPDATE orders SET study_id = (SELECT id FROM studies WHERE name = 'Example project') WHERE study_id IN (4, 36)";
		# nothing to do for project_id
    ActiveRecord::Base.transaction do
      Orders.find_by_id(2).update_attributes!(:study_id => 85)
      Orders.find_by_id(163).update_attributes!(:study_id => 85)
    end
  end

  def self.down
  	#execute "UPDATE orders SET study_id = 4 WHERE id =2";
  	#execute "UPDATE orders SET study_id = 36 WHERE id = 163";
		# nothing to do for project_id
    ActiveRecord::Base.transaction do
      Orders.find_by_id(2).update_attributes!(:study_id => 4)
      Orders.find_by_id(163).update_attributes!(:study_id => 36)
    end
  end
end
