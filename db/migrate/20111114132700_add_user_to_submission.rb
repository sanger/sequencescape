class AddUserToSubmission < ActiveRecord::Migration
  def self.up
    Submission.transaction do
      ActiveRecord::Base.connection.execute %Q{
      UPDATE submissions
      JOIN orders ON (orders.submission_id = submissions.id)
      SET submissions.user_id=orders.user_id
      WHERE submissions.user_id is NULL
}
      #Backfill
    end
  end

  def self.down
      rename_column(:submissions, :user_id, :user_id_to_delete)
  end
end
