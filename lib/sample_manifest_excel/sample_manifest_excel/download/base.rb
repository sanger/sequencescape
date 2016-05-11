module SampleManifestExcel
  module Download
    class Base

      attr_reader :sample_manifest, :data_worksheet, :type, :styles, :range_list, :ranges_worksheet, :column_list
      attr_accessor :columns_names

      def initialize(sample_manifest, full_column_list, range_list, styles_data)
        @sample_manifest = sample_manifest
        @styles = create_styles(styles_data)
        @range_list = range_list
        @column_list = full_column_list.extract(self.class.column_names)
        @ranges_worksheet = SampleManifestExcel::Worksheet::RangesWorksheet.new(ranges: range_list, workbook: workbook, password: password)
        @data_worksheet = SampleManifestExcel::Worksheet::DataWorksheet.new(workbook: workbook, columns: column_list, sample_manifest: sample_manifest, styles: styles, ranges: range_list, password: password, type: type)
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

      def insert_worksheet(index=0, name)
        workbook.insert_worksheet(index, name: name)
      end

      def self.column_names
        @column_names ||= []
      end

      def type
        ''
      end

    private

      def create_styles(styles_data)
        {}.tap do |s|
          styles_data.each do |name, options|
            s[name] = SampleManifestExcel::Style.new workbook, options
          end
        end
      end

    end
  end
end