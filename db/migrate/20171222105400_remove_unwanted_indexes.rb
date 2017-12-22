class RemoveUnwantedIndexes < ActiveRecord::Migration[5.1]
  def change
    remove_index :transfer_requests, column: ["billing_product_id"]
    remove_index :transfer_requests, column: ["initial_project_id"]
    remove_index :transfer_requests, column: ["initial_study_id", "request_type_id", "state"]
    remove_index :transfer_requests, column: ["initial_study_id"]
    remove_index :transfer_requests, column: ["item_id"]
    remove_index :transfer_requests, column: ["request_type_id", "state"]
    remove_index :transfer_requests, column: ["state", "request_type_id", "initial_study_id"]
    remove_index :transfer_requests, column: ["updated_at"]
    remove_index :transfer_requests, column: ["work_order_id"]
  end
end
