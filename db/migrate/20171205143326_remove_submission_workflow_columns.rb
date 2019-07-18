# Submission workflows have been removed, so we remove the associations
# that are associated with them.
class RemoveSubmissionWorkflowColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :orders, :workflow_id, :integer
    remove_column :requests, :workflow_id, :integer
    remove_column :users, :workflow_id, :integer
    remove_column :items, :workflow_id, :integer
    remove_column :request_types, :workflow_id, :integer
  end
end
