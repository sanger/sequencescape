class ReplaceAttachmentfuPaperclip < ActiveRecord::Migration
  # Note that this assumes the carrierwave code is in place before migration rollback
  def self.up
    say "Changing documents table"
            # Documents has extra column for multiple 1-1 relationships
            change_table :documents do |t|
              t.column :documentable_extended, :string
            end
             
             say "Making db_files polymorphic"
             # Db Files becomes polymorphic
             change_table :db_files do |t|
               t.column :owner_type, :string, :default => 'Document'
               # extra field in case 1-1 mapping needed on multiple fields
               t.column :owner_type_extended, :string 
               t.rename :document_id, :owner_id
             end
             
             say "Study reports - migration to using CarrierWave"
             # Add metadata columns for study reports
             change_table :study_reports do |t|
               t.column :report_filename, :string
               t.column :content_type, :string,  :default => "text/csv"
             end
     
     # Create files from existing study reports
     StudyReport.all.each do |r|
       DbFile.create!(:data => r.report_file, :owner => r)
       r.report_filename="#{r.study.dehumanise_abbreviated_name}_progress_report.csv"
       r.content_type="text/csv"
       r.save
     end
     # Remove the old data column
     change_table :study_reports do |t|
       t.remove :report_file
     end
     
     say "Plate volumes migration"
     # Plate volumes already have filenames
     # Create files from existing plate volume data
     PlateVolume.all.each do |p|
       DbFile.create!(:data => p.uploaded_file, :owner => p)
       p.uploaded_file_name="#{p.id}.csv"
       p.save
     end
     # Remove old data column
     change_table :plate_volumes do |t|
       t.remove :uploaded_file
     end
     
     say "Sample manifest migration"
     # Sample manifests
     change_table :sample_manifests do |t|
       t.column :uploaded_filename, :string
       t.column :generated_filename, :string
     end
     SampleManifest.all.each do |s| 
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
    change_table :sample_manifests do |t|
      t.remove :uploaded_file, :generated_file
    end
          
  end

  def self.down
    
    # Sample manifests
    change_table :sample_manifests do |t|
      t.column :uploaded_file,  :binary, :limit => 16.megabytes
      t.column :generated_file, :binary, :limit => 16.megabytes
    end
    say "Restoring sample manifests"
    SampleManifest.all.each do |sm|
      unless sm.uploaded_document.nil?
        sm.uploaded_file=sm.uploaded_document.current_data
        sm.uploaded_document.destroy # Cannot be delete
      end
      unless sm.generated_document.nil?
        sm.generated_file=sm.generated_document.current_data
        sm.generated_document.destroy # Cannot be delete
      end
      sm.save
    end
    change_table :sample_manifests do |t|
      t.remove :uploaded_filename, :generated_filename
    end
    
    # Restore data column to study reports
    change_table :study_reports do |t|
      t.column :report_file, :binary
    end
    # Create files from existing reports
    StudyReport.all.each do |r|
      r.report_file=r.report.file.read
      r.db_files.each { |f| f.destroy }
      r.save
    end
    # Remove metadata columns
    change_table :study_reports do |t|
     t.remove :report_filename, :content_type
   end
 
   # Plate volumes
   #  Replace old data column
   change_table :plate_volumes do |t|
      t.column :uploaded_file, :binary, :limit => 16.megabytes
   end
   #  Create files from existing plate volume data
   PlateVolume.all.each do |p|
     p.uploaded_file=p.uploaded.file.read
     p.db_files.each { |f| f.destroy }
     p.save
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
