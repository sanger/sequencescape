class RemoveSampleFromRequests < ActiveRecord::Migration
  def self.up
    remove_columns :requests, :sample_id
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
