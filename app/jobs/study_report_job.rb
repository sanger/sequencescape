# Generate a study report. Largely replaced by {QcReport}
StudyReportJob = Struct.new(:study_report_id) do
  def perform
    StudyReport.find(study_report_id).perform
  end
end
