module SampleManifestExcel
  class TestDownload
    include ActiveModel::Model
    include DownloadHelpers

    attr_reader :worksheet

    def initialize(attributes = {})
      @worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(workbook: workbook))
    end
  end
end
