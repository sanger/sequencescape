class PaperclipTables < ActiveRecord::Migration
 
  def self.up
    # Add metadata columns
    change_table :study_reports do |t|
      t.column :report_filename, :string
      t.column :content_type, :string,  :default => "text/csv"
    end
    # Create files from existing reports
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
    
  end
  
  def self.down
    # Restore column
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
  end
end
