# Generate CreateAssetRequests for the provided assets, linking them to the study.
# Currently used in Tube sample manifests.
# JG: Not entirely sure this is all that useful any more.
QcReportJob = Struct.new(:qc_report_id) do
  def perform
    QcReport.find(qc_report_id).generate!
  end
end
