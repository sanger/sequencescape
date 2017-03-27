QcReportJob = Struct.new(:qc_report_id) do
  def perform
    QcReport.find(qc_report_id).generate!
  end
end
