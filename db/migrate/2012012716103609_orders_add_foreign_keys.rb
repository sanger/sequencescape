# 2012012716103610_orders_constraint_ddl.rb

class OrdersAddForeignKeys < ActiveRecord::Migration
  def self.up
		execute "ALTER TABLE orders ADD CONSTRAINT FOREIGN KEY fk_orders_on_study_id (study_id) REFERENCES studies(id)"
		execute "ALTER TABLE orders ADD CONSTRAINT FOREIGN KEY fk_orders_on_project_id (project_id) REFERENCES projects(id)"
  end

  def self.down
		execute "ALTER TABLE orders DROP FOREIGN KEY fk_orders_on_study_id";
		execute "ALTER TABLE orders DROP FOREIGN KEY fk_orders_on_project_id";
  end
end


