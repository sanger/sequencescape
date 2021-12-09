class DropAkerTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :aker_containers
    drop_table :aker_jobs
    drop_table :sample_jobs
  end
end
