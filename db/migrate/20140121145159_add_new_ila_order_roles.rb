class AddNewIlaOrderRoles < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      each_role do |role|
        Order::OrderRole.create!(:role=>role)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      each_role do |role|
        Order::OrderRole.find_by_role(role).destroy
      end
    end
  end

  def self.each_role
    ['ILA ISC',].each do |role|
      yield role
    end
  end
end
