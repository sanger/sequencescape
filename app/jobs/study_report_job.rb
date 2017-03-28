# Generate CreateAssetRequests for the provided assets, linking them to the study.
# Currently used in Tube sample manifests.
# JG: Not entirely sure this is all that useful any more.
StudyReportJob = Struct.new(:study_report_id) do
  def perform
    StudyReport.find(study_report_id).perform
  end
end
