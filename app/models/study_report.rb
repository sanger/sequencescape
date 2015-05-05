#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class StudyReport < ActiveRecord::Base
  extend DbFile::Uploader
  include DelayedJobEx # add send_later_with_priority. need for delayed job 2.0.x
  class ProcessingError < Exception
  end
  cattr_reader :per_page
  @@per_page = 50

  named_scope :for_study, lambda { |study| { :conditions => { :study_id => study.id } } }
  named_scope :for_user, lambda { |user| { :conditions => { :user_id => user.id } } }
  #named_scope :without_files, lambda { select_without_file_columns_for(:report) }

  has_uploaded :report, {:serialization_column => "report_filename"}

  belongs_to :study
  belongs_to :user
  validates_presence_of :study

  def headers
     ["Study","Sample Name","Plate","Supplier Volume","Supplier Concentration","Supplier Sample Name",
       "Supplier Gender", "Concentration","Sequenome Count", "Sequenome Gender",
       "Pico","Gel", "Qc Status", "Genotyping Status", "Genotyping Chip", "Is in Fluidigm"]
   end

  def synchronous_perform
    ActiveRecord::Base.transaction do
      csv_options =  {:row_sep => "\r\n", :force_quotes => true }
      Tempfile.open("#{self.study.dehumanise_abbreviated_name}_progress_report.csv") do |tempfile|
        Study.find(self.study_id).progress_report_on_all_assets do |fields|
          tempfile.puts(FasterCSV.generate_line(fields, csv_options))
        end
        tempfile.open  # Reopen the temporary file
        self.update_attributes!(:report => tempfile)
      end
    end
  end

  # we don't use handle_asynchronously because it doesn't accept the priority options (in the version 2.0.3)
  # handle_asynchronously :perform
  def perform
   conf_priority = configatron.delayed_job.study_report_priority
   priority = conf_priority.present? ? conf_priority : 100

   send_later_with_priority(priority, :synchronous_perform)

   #job = Delayed::PerformableMethod.new(self, :synchronous_perform, [])
   #elayed::Job.enqueue(job, priority)
  end

end
