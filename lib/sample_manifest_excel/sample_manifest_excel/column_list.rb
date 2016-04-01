module SampleManifestExcel
  class ColumnList

    include Enumerable

    attr_reader :columns 

    def initialize(columns)
      @columns = create_columns(columns)
    end

    def each(&block)
      columns.each(&block)
    end

    def headings
      columns.collect(&:heading)
    end

  private

    def create_columns(columns)
      [].tap do |c|
        columns.each do |k, v|
          column = SampleManifestExcel::Column.new((v || {}).merge(name: k))
          c << column if column.valid?
        end
      end
    end
  end
end