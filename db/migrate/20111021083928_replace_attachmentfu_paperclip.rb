class ReplaceAttachmentfuPaperclip < ActiveRecord::Migration
  # Note that this assumes the carrierwave code is in place before rollback
  def self.up
    # Db Files becomes polymorphic
    change_table :db_files do |t|
      t.column :owner_type, :string, :default => 'Document'
      # In order to allow for one-one mapping on multiple columns we need an extra field:
      t.column :owner_type_extended, :string 
      t.rename :document_id, :owner_id
      
    end
    
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
    
    # Plate volumes
    #   Create files from existing plate volume data
    PlateVolume.all.each do |p|
      DbFile.create!(:data => p.uploaded_file, :owner => p)
      p.save
    end
    # Remove old data column
    change_table :plate_volumes do |t|
      t.remove :uploaded_file
    end
    
    # Sample manifests
    change_table :sample_manifests do |t|
      t.column :uploaded_filename, :string
      t.column :generated_filename, :string
    end
    SampleManifest.all.each do |s|
      DbFile.create!(:data => s.uploaded_file, :owner => s, :owner_type_extended => "uploaded")
      DbFile.create!(:data => s.generated_file, :owner => s, :owner_type_extended => "generated")
    end
    # change_table :sample_manifests do |t|
    #      t.remove :uploaded_file, :generated_file
    #    end
    #    
  end



  def self.down
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
     t.column :uploaded_file, :binary
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
 end
end
