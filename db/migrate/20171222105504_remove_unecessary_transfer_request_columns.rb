# frozen_string_literal: true

# There are LOTS of associations that transfer_requests simply don't care about
class RemoveUnecessaryTransferRequestColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :transfer_requests, :request_type_id, :integer
    remove_column :transfer_requests, :initial_study_id, :integer
    remove_column :transfer_requests, :initial_project_id, :integer
    remove_column :transfer_requests, :user_id, :integer
    remove_column :transfer_requests, :sample_pool_id, :integer
    remove_column :transfer_requests, :item_id, :integer
    remove_column :transfer_requests, :pipeline_id, :integer
    remove_column :transfer_requests, :charge, :boolean
    remove_column :transfer_requests, :priority, :integer
    remove_column :transfer_requests, :request_purpose_id, :integer
    remove_column :transfer_requests, :work_order_id, :integer
    remove_column :transfer_requests, :billing_product_id, :integer
  end
end
