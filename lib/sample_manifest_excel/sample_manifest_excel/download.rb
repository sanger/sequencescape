module SampleManifestExcel
  class Download
    include ActiveModel::Model
    include Helpers::Download

    validates_presence_of :sample_manifest, :column_list, :range_list

    attr_reader :sample_manifest, :data_worksheet, :range_list, :ranges_worksheet, :column_list

    def initialize(sample_manifest, column_list, range_list)
      @sample_manifest = sample_manifest
      @range_list = range_list
      @column_list = column_list

      if valid?
        @ranges_worksheet = Worksheet::RangesWorksheet.new(ranges: range_list, workbook: workbook, password: password)
        @data_worksheet = Worksheet::DataWorksheet.new(workbook: workbook, columns: column_list, sample_manifest: sample_manifest, ranges: range_list, password: password)
      end
    end

    def password
      @password ||= SecureRandom.base64
    end
  end
end
