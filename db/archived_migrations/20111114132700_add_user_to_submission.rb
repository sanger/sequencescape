#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddUserToSubmission < ActiveRecord::Migration
  def self.up
      rename_column(:submissions, :user_id_to_delete, :user_id)
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
