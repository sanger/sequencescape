class Carrierwave < ActiveRecord::Migration
  def self.up
    say "Updating documents to allow multiple 1-1 relationships"
    # Documents has extra column for multiple 1-1 relationships
    add_column :documents, :documentable_extended, :string, :limit => 25, :null => false
    change_column :documents, :documentable_type, :string, :limit => 50

    say "Making db_files polymorphic"
    add_column :db_files, :owner_type, :string, :default => 'Document', :limit => 25, :null => false
    # extra field in case 1-1 mapping needed on multiple fields
    add_column :db_files, :owner_type_extended, :string 
    rename_column :db_files, :document_id, :owner_id
    
    # Add metadata columns for study reports
    say "Study reports gain metadata columns"
    add_column :study_reports, :report_filename, :string
    add_column :study_reports, :content_type, :string, :default => "text/csv"
    
    # These indexes will help speed up queries for files
    add_index :db_files, [ :owner_type, :owner_id]
    add_index :documents, [ :documentable_type, :documentable_id]
  end
  
  def self.down
    # Remove metadata columns
    remove_column :study_reports, :report_filename, :content_type

    # Restore db_files so no longer polymorphic
    remove_column :db_files, :owner_type, :owner_type_extended
    rename_column :db_files, :owner_id,   :document_id

    # Documents has extra column for multiple 1-1 relationships
    remove_column :documents, :documentable_extended

  end
end