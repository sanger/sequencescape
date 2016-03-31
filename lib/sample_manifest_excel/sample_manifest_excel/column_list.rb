module SampleManifestExcel
  class ColumnList

    include Enumerable

    attr_reader :columns 

    def initialize(headings)
      @columns = headings.collect { |heading| SampleManifestExcel::Column.new(heading: heading) }
    end

    def each(&block)
      columns.each(&block)
    end

    def headings
      columns.collect(&:heading)
    end
  end
end