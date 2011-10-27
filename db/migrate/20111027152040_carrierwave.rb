class Carrierwave < ActiveRecord::Migration
  def self.up
    say "Changing documents table - can now have multiple 1-1 relationships on a model with documents"
    # Documents has extra column for multiple 1-1 relationships
    change_table :documents do |t|
      t.column :documentable_extended, :string
    end

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
    
    say "Sample manifest - filename columns"
    # Sample manifests
    change_table :sample_manifests do |t|
      t.column :uploaded_filename, :string
      t.column :generated_filename, :string
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
    
    # Remove file names from sample manifests
    change_table :sample_manifests do |t|
      t.remove :uploaded_filename, :generated_filename
    end
    
  end
end

class Carrierwave2 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do 
      # Create files from existing study reports
      StudyReport.all.each do |r|
        say "Migrating study report: #{r.study.dehumanise_abbreviated_name}"
        DbFile.create!(:data => r.report_file, :owner => r)
        r.report_filename="#{r.study.dehumanise_abbreviated_name}_progress_report.csv"
        r.content_type="text/csv"
        r.save
      end
    end
  end
  
  def self.down
    ActiveRecord::Base.transaction do 
      # Create files from existing reports
      StudyReport.all.each do |r|
        say "Reverting study report #{r.study.dehumanise_abbreviated_name}"
        r.report_file=r.report.file.read
        r.db_files.each { |f| f.destroy }
        r.save
      end
    end
  end
end

class MigratePlateVolumes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
       # Plate volumes already have filenames
       # Create files from existing plate volume data
      PlateVolume.all.each do |p|
        say "Migrating plate volume #{p.id}"
        DbFile.create!(:data => p.uploaded_file, :owner => p)
        p.save
      end
  end
  end
  
  def self.down
    ActiveRecord::Base.transaction do
      #  Create files from existing plate volume data
      PlateVolume.all.each do |p|
        say "Migrating plate volume #{p.id}"
        p.uploaded_file=p.uploaded.file.read
        p.db_files.each { |f| f.destroy }
        p.save
      end
    end
  end
end

class MigrateSampleManifests < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      SampleManifest.all.each do |s| 
        say "Migrating Sample Manifest #{s.id}"
        uploaded = Tempfile.new("sm-uploaded-#{s.id}.csv")
        File.open(uploaded.path, 'wb') do |f|
          f.write s.uploaded_file
        end
        generated = Tempfile.new("sm-generated-#{s.id}.xls")
        File.open(generated.path, 'wb') do |f|
          f.write s.generated_file
        end
        Document.create!(:uploaded_data => uploaded,  :documentable => s, :documentable_extended => "uploaded" )
        Document.create!(:uploaded_data => generated, :documentable => s, :documentable_extended => "generated")
        s.generated_filename="#{s.id}_generated.xls" #This is just so carrierwave thinks there is a file
        s.uploaded_filename="#{s.id}_uploaded.csv"
      end
    end
  end
  
  def self.down
    ActiveRecord::Base.transaction do
      SampleManifest.all.each do |sm|
        say "Migrating Sample Manifest #{sm.id}"
        unless sm.uploaded_document.nil?
          sm.uploaded_file=sm.uploaded_document.current_data
          sm.uploaded_document.destroy # Cannot be 'delete'
        end
        unless sm.generated_document.nil?
          sm.generated_file=sm.generated_document.current_data
          sm.generated_document.destroy # Cannot be 'delete'
        end
        sm.save
      end
    end
  end
end

# class FinalTableChanges < ActiveRecord::Migration
#   def self.up
#     say "Removing study reports data column"
#     change_table :study_reports do |t|
#       t.remove :report_file
#     end
#     
#     say "Removing plate volume data column"
#     change_table :plate_volumes do |t|
#       t.remove :uploaded_file
#     end
#     
#     say "Removing sample manifest data columns"
#     change_table :sample_manifests do |t|
#       t.remove :uploaded_file, :generated_file
#     end
#   end
#   
#   def self.down
#     say "Restore data column to study reports (does not migrate data back)"
#     change_table :study_reports do |t|
#       t.column :report_file, :binary
#     end
#     
#     say "Restore data column to plate volumes (does not migrate data back)"
#     change_table :plate_volumes do |t|
#       t.column :uploaded_file, :binary, :limit => 16.megabytes
#     end
#     
#     say "Restore data column to sample manifests (does not migrate data back)"
#     change_table :sample_manifests do |t|
#       t.column :uploaded_file,  :binary, :limit => 16.megabytes
#       t.column :generated_file, :binary, :limit => 16.megabytes
#     end
#   end
# end

