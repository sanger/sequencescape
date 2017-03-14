class AddWorkCompletionSubmissionTable < ActiveRecord::Migration
  def change
    create_table :work_completions_submissions do |t|
      t.references :work_completion, foreign_key: true, null: false
      t.references :submission, foreign_key: true, null: false
    end
  end
end
