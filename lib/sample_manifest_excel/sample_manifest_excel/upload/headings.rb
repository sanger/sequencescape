module SampleManifestExcel
  module Upload
    class Headings

      include Enumerable

      def initialize(headings, column_list)
      end

      def headings
        @headings ||= {}
      end

      def each(&block)
        headings.each(&block)
      end
    end
  end
end