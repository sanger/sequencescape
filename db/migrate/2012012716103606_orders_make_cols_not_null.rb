# 2012012716103605_orders_make_cols_not_null.rb

class OrdersMakeColsNotNull < ActiveRecord::Migration
  def self.up
		execute "ALTER TABLE orders MODIFY column study_id int(11) NOT NULL";
		execute "ALTER TABLE orders MODIFY column project_id int(11) NOT NULL";
		# nothing to do for project_id
  end

  def self.down
		execute "ALTER TABLE orders MODIFY column project_id int(11) DEFAULT NULL";
		execute "ALTER TABLE orders MODIFY column study_id int(11) DEFAULT NULL";
		# nothing to do for project_id
  end
end
