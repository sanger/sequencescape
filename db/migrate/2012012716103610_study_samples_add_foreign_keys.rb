# 2012012716103600_study_samples_constraint_ddl.rb

class StudySamplesAddForeignKeys < ActiveRecord::Migration
  def self.up
		execute "ALTER TABLE study_samples ADD CONSTRAINT FOREIGN KEY fk_study_samples_on_study_id (study_id) REFERENCES studies (id)";
		execute "ALTER TABLE study_samples ADD CONSTRAINT FOREIGN KEY fk_study_samples_on_sample_id (sample_id) REFERENCES samples (id)";
  end

  def self.down
		execute "ALTER TABLE study_samples DROP FOREIGN KEY study_samples_ibfk_1";
		execute "ALTER TABLE study_samples DROP FOREIGN KEY study_samples_ibfk_2";
  end
end


