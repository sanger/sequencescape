# 201201216103605_project_metadata_constraint_ddl.rb

class ProjectMetadataAddForeignKeys < ActiveRecord::Migration
  def self.up
		execute "ALTER TABLE project_metadata ADD CONSTRAINT FOREIGN KEY fk_project_metadata_on_project_id (project_id) REFERENCES projects(id)"
  end

  def self.down
		execute "ALTER TABLE project_metadata DROP FOREIGN KEY project_metadata_ibfk_1";
  end
end


