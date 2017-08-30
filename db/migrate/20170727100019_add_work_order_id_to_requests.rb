class AddWorkOrderIdToRequests < ActiveRecord::Migration
  def change
    add_reference :requests, :work_order, foreign_key: true, index: true
  end
end
