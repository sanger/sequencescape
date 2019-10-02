# Triggers {QcReport} generation, which involves extracting qc metric from
# various sources
QcReportJob = Struct.new(:qc_report_id) do
  def perform
    QcReport.find(qc_report_id).generate!
  end
end
