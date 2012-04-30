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
