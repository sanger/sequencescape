# frozen_string_literal: true

# Extracts location information for the {LocationReport}
LocationReportJob = Struct.new(:location_report_id) do
  def perform
    LocationReport.find(location_report_id).generate!
  end
end
