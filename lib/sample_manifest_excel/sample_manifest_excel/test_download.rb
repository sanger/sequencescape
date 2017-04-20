module SampleManifestExcel
  class TestDownload
    include ActiveModel::Model
    include Helpers::Download

    attr_reader :worksheet

    def initialize(attributes = {})
      @worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(workbook: workbook))
    end
  end
end
