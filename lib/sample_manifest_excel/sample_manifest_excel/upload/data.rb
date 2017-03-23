module SampleManifestExcel
  module Upload
    class Data
      include ActiveModel::Model
      include Enumerable

      attr_reader :sheet, :header_row, :data, :start_row, :filename

      validates_presence_of :start_row, :filename

      def initialize(filename, start_row)
        @filename = filename
        @start_row = start_row

        if valid?
          @sheet = Roo::Spreadsheet.open(filename).sheet(0)
          @header_row = sheet.row(start_row)
          @data = sheet.drop(start_row)
        end
      end

      def each(&block)
        data.each(&block)
      end

      def cell(row, column)
        data.try(:fetch, row - 1).try(:fetch, column - 1)
      end

      def column(n)
        data.map { |row| row[n - 1] }
      end

      def inspect
        "<#{self.class}: @header_row=#{header_row}, @data=#{data}, @start_row=#{start_row}, @filename=#{filename}>"
      end
    end
  end
end
