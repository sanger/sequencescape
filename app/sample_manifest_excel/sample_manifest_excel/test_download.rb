# frozen_string_literal: true

module SampleManifestExcel
  ##
  # Test download
  class TestDownload
    include ActiveModel::Model
    include SequencescapeExcel::Helpers::Download

    attr_reader :worksheet

    def initialize(attributes = {})
      @worksheet = SampleManifestExcel::Worksheet::TestWorksheet.new(attributes.merge(workbook:))
    end
  end
end
