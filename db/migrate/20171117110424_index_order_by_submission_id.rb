class IndexOrderBySubmissionId < ActiveRecord::Migration[5.1]
  def change
    add_index :orders, :submission_id
  end
end
