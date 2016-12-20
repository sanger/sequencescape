class AddRequestStateChangeSubmissionTable < ActiveRecord::Migration
  def change
    create_table :request_state_changes_submissions, id: false do |t|
      t.references :request_state_change, foreign_key: true, null: false
      t.references :submission, foreign_key: true, null: false
    end
  end
end
