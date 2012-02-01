# 201201216103616_sample_metadata_constraint_ddl.rb

class SampleMetadataAddForeignKeys < ActiveRecord::Migration
  def self.up
		execute "ALTER TABLE sample_metadata ADD CONSTRAINT FOREIGN KEY fk_sample_metadata_on_sample_id (sample_id) REFERENCES samples(id)"
  end

  def self.down
		execute "ALTER TABLE sample_metadata DROP FOREIGN KEY fk_sample_metadata_on_sample_id"
  end
end


