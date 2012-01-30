# 2012012716103605_orders_constraint_dml.rb

class OrdersFixForeignKeys < ActiveRecord::Migration
  def self.up
  	execute "UPDATE orders SET study_id = (SELECT id FROM studies WHERE name = 'Example project') WHERE study_id IN (4, 36)";
		execute "ALTER TABLE orders MODIFY column study_id int(11) NOT NULL";
		execute "ALTER TABLE orders MODIFY column sample_id int(11) NOT NULL";
		# nothing to do for project_id
  end

  def self.down
  	execute "UPDATE orders SET study_id = NULL WHERE study_id IN (4, 36)";
		execute "ALTER TABLE orders MODIFY column sample_id int(11) DEFAULT NULL";
		execute "ALTER TABLE orders MODIFY column study_id int(11) DEFAULT NULL";
		# nothing to do for project_id
  end
end
