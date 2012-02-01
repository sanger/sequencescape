# 2012012716103605_orders_fix_foreign_keys.rb

class OrdersFixForeignKeys < ActiveRecord::Migration
  def self.up
  	execute "UPDATE orders SET study_id = (SELECT id FROM studies WHERE name = 'Example project') WHERE study_id IN (4, 36)"
  	execute "UPDATE orders SET study_id = (SELECT id FROM studies WHERE name = 'Example project') WHERE study_id  = 0"
  	execute "UPDATE orders SET project_id = (SELECT id FROM projects WHERE name = 'Example project') WHERE project_id  = 0"

    # ruby version cannot be used without fixing
    # ruby-1.8.7-p174 >   @order.valid?
#NoMethodError: You have a nil object when you didn't expect it!
#You might have expected an instance of Array.
#The error occurred while evaluating nil.flatten

    # ActiveRecord::Base.transaction do
    #   Order.find_by_id(2).update_attributes!(:study_id => 85)
    #   Order.find_by_id(163).update_attributes!(:study_id => 85)
    #end
  end

  def self.down
  	execute "UPDATE orders SET study_id = 4 WHERE id = 2"
  	execute "UPDATE orders SET study_id = 36 WHERE id = 163"
    #ActiveRecord::Base.transaction do
    #  Order.find_by_id(2).update_attributes!(:study_id => 4)
    #  Order.find_by_id(163).update_attributes!(:study_id => 36)
    #end
  end
end
