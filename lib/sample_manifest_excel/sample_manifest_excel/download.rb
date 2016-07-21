module SampleManifestExcel
	class Download

    attr_reader :sample_manifest, :data_worksheet, :range_list, :ranges_worksheet, :column_list

    def initialize(sample_manifest, column_list, range_list)
      @sample_manifest = sample_manifest
      @range_list = range_list
      @column_list = column_list
      @ranges_worksheet = Worksheet::RangesWorksheet.new(ranges: range_list, workbook: workbook, password: password)
      @data_worksheet = Worksheet::DataWorksheet.new(workbook: workbook, columns: column_list, sample_manifest: sample_manifest, ranges: range_list, password: password)
    end

    def save(filename)
      xls.serialize(filename)
    end

    def password
      @password ||= SecureRandom.base64
    end

    def xls
      @xls ||= Axlsx::Package.new
    end

    def workbook
      @workbook ||= xls.workbook
    end

  end

end