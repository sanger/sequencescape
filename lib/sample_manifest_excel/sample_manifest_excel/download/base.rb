module SampleManifestExcel
  module Download
    class Base

      attr_reader :sample_manifest, :data_worksheet, :type, :range_list, :ranges_worksheet, :column_list
      attr_accessor :columns_names

      #A download takes:
      #- sample manifest object (from ss),
      #- full column list object (has information about all columns
      #  that can be used in different excel sample manifests),
      #- range list object (has information about all ranges that can be used
      #  by various columns in data validation drop-down list),
      #- styles data (a hash, that has styles names as keys and options required
      #  for different styles as values, an example of a hash is in file
      #  test/data/sample_manifest_excel/sample_manifest_styles.yml)
      #
      #Download extracts the required columns from full column list and creates a workbook
      #that consists of 2 worksheets:
      #- data worksheet (to be filled in by the clients). It is locked except for the cells
      #  to be filled in.
      #- ranges worksheet, that contains information about ranges used in data validation and
      #  conditional formatting. This worksheet is locked.

      def initialize(sample_manifest, full_column_list, range_list)
        @sample_manifest = sample_manifest
        @range_list = range_list
        @column_list = full_column_list.extract(self.class.column_names)
        @ranges_worksheet = SampleManifestExcel::Worksheet::RangesWorksheet.new(ranges: range_list, workbook: workbook, password: password)
        @data_worksheet = SampleManifestExcel::Worksheet::DataWorksheet.new(workbook: workbook, columns: column_list, sample_manifest: sample_manifest, ranges: range_list, password: password, type: type)
      end

      #Saves file as xlsx document. filename is a name of the file that will be saved.

      def save(filename)
        xls.serialize(filename)
      end

      #Generates a password

      def password
        @password ||= SecureRandom.base64
      end

      #Initializes an axlsx package

      def xls
        @xls ||= Axlsx::Package.new
      end

      #Adds a workbook

      def workbook
        @workbook ||= xls.workbook
      end

      #Returns a list of column names specific to a particular type of sample manifest

      def self.column_names
        @column_names ||= []
      end

      #Returns a type of asset used in particular sample manifest ('Plates' or 'Tubes')

      def type
        ''
      end

    end
  end
end