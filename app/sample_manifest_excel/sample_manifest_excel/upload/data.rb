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
      validates :file_extension, inclusion: { in: ['.csv', '.xlsx'].freeze, message: 'is unsupported; should be csv or xlsx' }
      validate :file_errors_empty

      ##
      # The file is opened as a Roo spreadsheet.
      # If it is valid it is split by the start row.
      # Start row of column headers and data put into separate rows.
      def initialize(file, start_row)
        @file = file
        @start_row = start_row
        @file_errors = nil
        if valid?
          @sheet = read_sheet
          @header_row = sheet&.row(start_row)
          @data = sheet&.drop(start_row)
          @description_info = extract_description_info(sheet, start_row)
        end
      ensure
        @header_row ||= []
        @data ||= []
      end

      def each(&block)
        data.each(&block)
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
        "<#{self.class}: @header_row=#{header_row}, @data=#{data}, @start_row=#{start_row}, @file=#{file}>"
      end

      def extract_description_info(sheet, start_row)
        # look through the rows from under the heading (row 2), to above the start row
        # build a hash of first cell => second cell
        output = {}
        (2..start_row-1).each do |row_num|
          row = sheet.row(row_num)
          output[row[0]] = row[1] unless row[0] == nil
        end
        output
      end
    end
  end
end
