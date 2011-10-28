
  
class StudyReport < ActiveRecord::Base
  has_many :db_files, :as => :owner, :dependent => :destroy
  #   Mount Carrierwave on report field
  mount_uploader :report, PolymorphicUploader, :mount_on => "report_filename"
end

class PlateVolume < ActiveRecord::Base
  # New file storage:
  has_many :db_files, :as => :owner, :dependent => :delete_all
  #  Mount Carrierwave on report field
  mount_uploader :uploaded, PolymorphicUploader, :mount_on => "uploaded_file_name"
end

class SampleManifest < ActiveRecord::Base
end



class CarrierwaveData < ActiveRecord::Migration
   module DbFileStorage
     def self.store(file, o_id, o_type)
       each_slice(file) do |start, finish|
         DbFile.create!(:data => file.slice(start, finish), :owner_id => o_id, :owner_type => o_type)
       end
     end
     def self.each_slice(data)
       max_part_size = 200.kilobytes
       beginning =0;
       left = data.size
       while left>0
         part_size = [left, max_part_size].min
         yield beginning, part_size
         beginning += part_size
         left -= part_size
       end
     end
   end
  def self.up
    ActiveRecord::Base.transaction do 
      # Create files from existing study reports
      StudyReport.all.each do |r|
        say "Migrating study report: #{r.id}"
        # DbFile.create!(:data => r.report_file, :owner_type => "StudyReport", :owner_id => r.id)
        DbFileStorage.store(r.report_file, r.id, "StudyReport") unless r.report_file.nil?
        r.report_filename="#{r.id}_progress_report.csv"
        r.content_type="text/csv"
        r.save
      end
   
      SampleManifest.all.each do |s| 
        say "Migrating sample manifest: #{s.id}"
        unless s.uploaded_file.nil?
          uploaded = Tempfile.new("sm-uploaded-#{s.id}.csv")
          File.open(uploaded.path, 'wb') do |f|
            f.write s.uploaded_file
          end
          Document.create!(:uploaded_data => uploaded,  :documentable_id => s.id, :documentable_type => "SampleManifest", :documentable_extended => "uploaded" )
        end
        unless s.generated_file.nil?
          generated = Tempfile.new("sm-generated-#{s.id}.xls")
          File.open(generated.path, 'wb') do |f|
            f.write s.generated_file
          end
          Document.create!(:uploaded_data => generated, :documentable_id => s.id, :documentable_type => "SampleManifest", :documentable_extended => "generated")
        end
        s.generated_filename="#{s.id}_generated.xls" #This is just so carrierwave thinks there is a file
        s.uploaded_filename="#{s.id}_uploaded.csv" #This is just so carrierwave thinks there is a file
      end
      
       # Plate volumes already have filenames
       # Create files from existing plate volume data
      PlateVolume.all.each do |p|
        say "Migrating plate volume: #{p.id}"
        DbFileStorage.store(p.uploaded_file, p.id, "PlateVolume") unless p.uploaded_file.nil?
        # DbFile.create!(:data => p.uploaded_file, :owner => p)
       #  p.save
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      SampleManifest.all.each do |sm|
        uploaded_doc  = Document.first(:conditions => ["documentable_id = ? AND documentable_extended = ?", sm.id, 'uploaded'])
        generated_doc = Document.first(:conditions => ["documentable_id = ? AND documentable_extended = ?", sm.id, 'generated'])
        say "Migrating sample manifest: #{sm.id}"
        unless uploaded_doc.nil?
          sm.uploaded_file=uploaded_doc.current_data
          uploaded_doc.destroy
        end
        unless generated_doc.nil?
          sm.generated_file=generated_doc.current_data
          generated_doc.destroy
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
        say "Reverting study report: #{r.id}"
        r.report_file=r.report.file.read
       #  files = DbFile.find :all, :conditions => ["owner_type = \'StudyReport\' AND owner_id = ?", r.id]
        # files.each { |f| f.destroy }
        r.db_files.each { |f| f.destroy }
        r.save
      end
    end
  end
end
