#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddNotNullConstraintToBatchRequests < ActiveRecord::Migration
  def self.up
    alter_table(:batch_requests) do
      rename_column :batch_id, :batch_id, :integer, :null => false
      rename_column :request_id, :request_id, :integer, :null => false
      remove_column :depricated_qc_state
    end
  end

  def self.down
    # Nothing to do here as this is a constraint that was valid before this point
  end
end
