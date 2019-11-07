# A spreadsheet summarising the QC information about a study.
# Generally replaced by {QcReport} which adds support for pass/fail criteria,
# automatic decisions and customer decisions.
class StudyReport < ApplicationRecord
  extend DbFile::Uploader

  class ProcessingError < RuntimeError
  end

  self.per_page = 50

  scope :for_study, ->(study) { where(study_id: study.id) }
  scope :for_user, ->(user) { where(user_id: user.id) }

  has_uploaded :report, serialization_column: 'report_filename'

  belongs_to :study
  belongs_to :user
  validates :study, presence: true

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
        update!(report: tempfile)
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
