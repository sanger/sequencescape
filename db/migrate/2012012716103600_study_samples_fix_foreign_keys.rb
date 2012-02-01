class StudySamplesFixForeignKeys < ActiveRecord::Migration
def self.up
    execute "CREATE TABLE keep_study_samples AS SELECT *  FROM study_samples WHERE id IN (2, 163, 2750, 2786, 2787, 2797, 2798, 21063, 21065, 21067)"
    execute "DELETE from study_samples where id in (1, 2, 163, 2750, 2786, 2787, 2797, 2798, 21063, 21065, 21067, 1119669)"
end

  def self.down
  	raise ActiveRecord::IrreversibleMigration, "The deleted study_sample rows are in the table keep_study_samples, but note that they cannot be put back in without altering the ids relied upon by this migration"
  end
end

   
	
