# 2012012716103610_study_metadata_constraint_ddl.rb

class StudyMetadataAddForeignKeys < ActiveRecord::Migration
  def self.up
		execute "ALTER TABLE study_metadata ADD CONSTRAINT FOREIGN KEY fk_study_metadata_on_study_id (study_id) REFERENCES studies(id)"
		execute "ALTER TABLE study_metadata ADD CONSTRAINT FOREIGN KEY fk_study_metadata_on_project_id (project_id) REFERENCES projects(id)"
  end

  def self.down
		execute "ALTER TABLE study_metadata DROP FOREIGN KEY fk_study_metadata_on_study_id";
		execute "ALTER TABLE study_metadata DROP FOREIGN KEY fk_study_metadata_on_project_id";
  end
end


