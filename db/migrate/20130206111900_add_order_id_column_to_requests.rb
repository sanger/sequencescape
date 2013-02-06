class AddOrderIdColumnToRequests < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :requests, :order_id, :integer
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :requests, :order_id
    end
  end
end
