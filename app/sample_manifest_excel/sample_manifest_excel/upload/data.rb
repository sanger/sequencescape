# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    ##
    # An object to store the data for a particular manifest upload.
    # The data is split into a header row (column names) and the actual data.
    class Data
      include ActiveModel::Model
      include Enumerable
      include Converters

      attr_reader :sheet, :header_row, :data, :start_row, :file, :description_info

      validates_presence_of :start_row, :file
      validates :file_extension,
                inclusion: {
                  in: %w[.csv .xlsx].freeze,
                  message: 'is unsupported; should be csv or xlsx'
                }
      validate :file_errors_empty

      SANGER_SAMPLE_ID_COLUMN_LABEL = 'SANGER SAMPLE ID'

      ##
      # The file is opened as a Roo spreadsheet.
      # If it is valid it is split by the start row.
      # Start row of column headers and data put into separate rows.
      def initialize(file) # rubocop:todo Metrics/MethodLength
        @file = file
        @file_errors = nil
        @sheet = read_sheet
        @start_row = find_start_row
        return if @start_row.nil?

        @header_row = sheet&.row(@start_row)
        @data = sheet&.drop(@start_row)
        @description_info = extract_description_info(sheet, @start_row)
      ensure
        @header_row ||= []
        @data ||= []
      end

      def each(&)
        data.each(&)
      end

      def file_extension
        return nil if file.nil?

        File.extname(file.path)
      end

      ##
      # Find a cell of data based on the column and row
      def cell(row, column)
        val = data.try(:fetch, row - 1).try(:fetch, column - 1)
        strip_all_blanks(val)
      end

      ##
      # Return a column of data for a particular column number
      def column(col_num)
        data.map do |row|
          val = row[col_num - 1]
          strip_all_blanks(val)
        end
      end

      def read_sheet
        return nil if file.nil?

        Roo::Spreadsheet.open(file).sheet(0)
        # In production we see a variety of errors here, all of which indicate problems with the manifest
      rescue StandardError => e
        # We store the errors in an instance variable, as otherwise they get lost on any subsequent
        # calls to #valid?
        @file_errors = "could not be read: #{e.message}"
        nil
      end

      def file_errors_empty
        errors.add(:file, @file_errors) if @file_errors.present?
      end

      def inspect
        "<#{self.class}: @header_row=#{header_row}, @data=#{data}, @start_row=#{@start_row}, @file=#{file}>"
      end

      def find_start_row
        return nil if sheet.nil?

        (0..sheet.last_row).each do |row_num|
          sheet.row(row_num).each { |cell_value| return row_num if cell_value == SANGER_SAMPLE_ID_COLUMN_LABEL }
        end

        nil
      end

      def extract_description_info(sheet, start_row)
        # look through each row starting from from under the heading (row 2), to above the start row
        # build a hash of the value in the first column => value in second column
        # this was built to extract the tube rack barcodes, and assumes the label is in the first column and the value
        # in the second
        return nil if sheet.nil? || start_row.nil?

        output = {}
        (2..(start_row - 1)).each do |row_num|
          row = sheet.row(row_num)
          info_label = row[0]
          info_value = row[1]
          output[info_label] = info_value unless info_label.nil?
        end
        output
      end
    end
  end
end
