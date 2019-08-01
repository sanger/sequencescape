# Rails migration
class AddWorkOrderIdToRequests < ActiveRecord::Migration[5.1]
  def change
    add_reference :requests, :work_order, foreign_key: true, index: true
  end
end
