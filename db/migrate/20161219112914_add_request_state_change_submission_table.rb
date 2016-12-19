class AddRequestStateChangeSubmissionTable < ActiveRecord::Migration
  def change
    create_table :request_state_change_submissions do |t|
      t.references :request_state_change, foreign_key: true, null: false
      t.references :submission, foreign_key: true, null: false
      t.timestamps
    end
  end
end
