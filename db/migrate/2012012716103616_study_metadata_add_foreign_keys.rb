# 201201216103616_study_metadata_constraint_ddl.rb

class StudyMetadataAddForeignKeys < ActiveRecord::Migration
  def self.up
		execute "ALTER TABLE study_metadata ADD CONSTRAINT FOREIGN KEY fk_study_metadata_on_study_id (study_id) REFERENCES studies(id)"
  end

  def self.down
		execute "ALTER TABLE study_metadata DROP FOREIGN KEY study_metadata_ibfk_1"
  end
end


