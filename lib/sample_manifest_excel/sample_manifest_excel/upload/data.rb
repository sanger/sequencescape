module SampleManifestExcel
  module Upload
    ##
    # An object to store the data for a particular manifest upload.
    # The data is split into a header row (clumn names) and the actual data.
    class Data
      include ActiveModel::Model
      include Enumerable

      attr_reader :sheet, :header_row, :data, :start_row, :filename

      validates_presence_of :start_row, :filename

      ##
      # The file is opened as a Roo spreadsheet.
      # If it is valid it is split by the start row.
      # Start row of colunn headers and data put into separate rows.
      def initialize(filename, start_row)
        @filename = filename
        @start_row = start_row

        if valid?
          @sheet = Roo::Spreadsheet.open(filename).sheet(0)
          @header_row = sheet.row(start_row)
          @data = sheet.drop(start_row)
        else
          @header_row = []
          @data = []
        end
      end

      def each(&block)
        data.each(&block)
      end

      ##
      # Find a cell of data based on the column and row
      def cell(row, column)
        data.try(:fetch, row - 1).try(:fetch, column - 1)
      end

      ##
      # Return a column of data for a particular column number
      def column(n)
        data.map { |row| row[n - 1] }
      end

      def inspect
        "<#{self.class}: @header_row=#{header_row}, @data=#{data}, @start_row=#{start_row}, @filename=#{filename}>"
      end
    end
  end
end
