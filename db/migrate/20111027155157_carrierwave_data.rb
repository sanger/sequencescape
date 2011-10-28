class CarrierwaveData < ActiveRecord::Migration
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
    
       # Plate volumes already have filenames
       # Create files from existing plate volume data
      PlateVolume.all.each do |p|
        say "Migrating plate volume: #{p.id}"
        DbFile.create!(:data => p.uploaded_file, :owner => p)
        p.save
      end
   
      SampleManifest.all.each do |s| 
        say "Migrating sample manifest: #{s.id}"
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
        say "Migrating sample manifest: #{sm.id}"
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
   
      #  Create files from existing plate volume data
      PlateVolume.all.each do |p|
        say "Migrating plate volume: #{p.id}"
        p.uploaded_file=p.uploaded.file.read
        p.db_files.each { |f| f.destroy }
        p.save
      end
    
      # Create files from existing reports
      StudyReport.all.each do |r|
        say "Reverting study report: #{r.study.dehumanise_abbreviated_name}"
        r.report_file=r.report.file.read
        r.db_files.each { |f| f.destroy }
        r.save
      end
    end
  end
end
