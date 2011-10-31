class CarrierWaveCleanup < ActiveRecord::Migration
  def self.up
    # Save space in the database (helps with indexes). 
    #  Really this should be less but namespacing might make it expand at some point
    change_column :documents, :documentable_type, :string, :limit => 50, :null => false
    change_column :db_files, :owner_type, :string, :limit => 50, :null => false
    
    # These indexes will help speed up queries for files
    add_index :db_files, [ :owner_type, :owner_id]
    add_index :documents, [ :documentable_type, :documentable_id]
   
    # Delete old file columns
    remove_column :study_reports, :report_file 
    remove_column :sample_manifests, :uploaded_file
    remove_column :sample_manifests, :generated_file
    remove_column :plate_volumes, :uploaded_file
  end

  def self.down
    # Replace file columns:
    add_column :study_reports, :report_file, :binary, :limit => 16.megabytes
    add_column :sample_manifests, :uploaded_file, :binary, :limit => 16.megabytes
    add_column :sample_manifests, :generated_file, :binary, :limit => 16.megabytes
    add_column :plate_volumes, :uploaded_file, :binary, :limit => 16.megabytes
  end
end
