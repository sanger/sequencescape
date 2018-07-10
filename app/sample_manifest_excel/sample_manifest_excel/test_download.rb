# frozen_string_literal: true

module SampleManifestExcel
  ##
  # Test download
  class TestDownload
    include ActiveModel::Model
    include Helpers::Download

    attr_reader :worksheet

    def initialize(attributes = {})
      @worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(workbook: workbook))
    end
  end
end
