# 2012012716103603_project_metadata_make_cols_null.rb

class ProjectMetadataMakeColsNull < ActiveRecord::Migration
  def self.up
		execute "ALTER TABLE project_metadata MODIFY column project_id int(11) NOT NULL";
  end

  def self.down
		execute "ALTER TABLE project_metadata MODIFY column project_id int(11) DEFAULT NULL";
  end
end


