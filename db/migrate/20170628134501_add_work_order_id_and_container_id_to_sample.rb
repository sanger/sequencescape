class AddWorkOrderIdAndContainerIdToSample < ActiveRecord::Migration
  def change
    add_column :samples, :work_order_id, :integer, index: true
    add_column :samples, :container_id, :integer, index: true
  end
end
