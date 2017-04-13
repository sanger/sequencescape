# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class StudyReport < ActiveRecord::Base
  extend DbFile::Uploader

  class ProcessingError < RuntimeError
  end

  self.per_page = 50

  scope :for_study, ->(study) { where(study_id: study.id) }
  scope :for_user, ->(user) { where(user_id: user.id) }
  # named_scope :without_files, -> { select_without_file_columns_for(:report) }

  has_uploaded :report, serialization_column: 'report_filename'

  belongs_to :study
  belongs_to :user
  validates_presence_of :study

  def headers
    [
      'Study', 'Sample Name', 'Plate', 'Supplier Volume', 'Supplier Concentration',
      'Supplier Sample Name', 'Supplier Gender', 'Concentration',
      'Sequenome Count', 'Sequenome Gender', 'Pico', 'Gel', 'Qc Status',
      'Genotyping Status', 'Genotyping Chip', 'Is in Fluidigm'
    ]
  end

  def perform
    ActiveRecord::Base.transaction do
      csv_options = { row_sep: "\r\n", force_quotes: true }
      Tempfile.open("#{study.dehumanise_abbreviated_name}_progress_report.csv") do |tempfile|
        Study.find(study_id).progress_report_on_all_assets do |fields|
          tempfile.puts(CSV.generate_line(fields, csv_options))
        end
        tempfile.open # Reopen the temporary file
        update_attributes!(report: tempfile)
      end
    end
  end

  def schedule_report
    Delayed::Job.enqueue StudyReportJob.new(id), priority: priority
  end

  def priority
    configatron.delayed_job.fetch(:study_report_priority, 100)
  end
end
