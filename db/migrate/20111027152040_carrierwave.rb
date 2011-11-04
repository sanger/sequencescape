class Carrierwave < ActiveRecord::Migration
  def self.up
    say "Changing documents table - can now have multiple 1-1 relationships on a model with documents"
    # Documents has extra column for multiple 1-1 relationships
    change_table :documents do |t|
      t.column :documentable_extended, :string, :limit => 50
    end
    change_column :documents, :documentable_type, :string, :limit => 25

    say "Making db_files polymorphic"
    change_table :db_files do |t|
      t.column :owner_type, :string, :default => 'Document'
      # extra field in case 1-1 mapping needed on multiple fields
      t.column :owner_type_extended, :string 
      t.rename :document_id, :owner_id
    end
    
    # Add metadata columns for study reports
    say "Study reports - extra columns"
    change_table :study_reports do |t|
      t.column :report_filename, :string
      t.column :content_type, :string,  :default => "text/csv"
    end
    
  end
  
  def self.down
    
    # Remove metadata columns
    change_table :study_reports do |t|
      t.remove :report_filename, :content_type
    end
    
    # Restore db_files so no longer polymorphic
    change_table :db_files do |t|
      t.remove :owner_type, :owner_type_extended
      t.rename :owner_id, :document_id
    end

    # Documents has extra column for multiple 1-1 relationships
    change_table :documents do |t|
      t.remove :documentable_extended
    end
    
  end
end