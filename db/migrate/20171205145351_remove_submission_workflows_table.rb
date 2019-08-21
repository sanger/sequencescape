# Remove the submission workflows feature, because it was confusing.
class RemoveSubmissionWorkflowsTable < ActiveRecord::Migration[5.1]
  def change
    drop_table 'submission_workflows', id: :integer, force: :cascade, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci' do |t|
      t.string 'key', limit: 50
      t.string 'name'
      t.string 'item_label'
      t.datetime 'created_at'
      t.datetime 'updated_at'
    end
  end
end
