module SampleManifestExcel
  class ColumnList

    include Enumerable

    attr_reader :columns 

    def initialize(columns = {})
      create_columns(columns)
      yield self if block_given?
    end

    def each(&block)
      columns.each(&block)
    end

    def headings
      columns.values.collect(&:heading)
    end

    def find_by(key)
      columns[key]
    end

    def extract(names)
      ColumnList.new do |column_list|
        names.each do |name|
          column_list.add find_by(name)
        end
      end
    end

    def with_attributes
      columns.values.select { |column| column.attribute? }
    end

    def add(column)
      return unless column.valid?
      columns[column.name] = column.set_position(next_position)
    end

    def add_with_dup(column)
      add(column.dup)
    end

    def next_position
      columns.count+1
    end

    def columns
      @columns ||= {}
    end

  private

    def create_columns(columns)
      columns.each do |k,v|
        add SampleManifestExcel::Column.new((v || {}).merge(name: k))
      end
    end
  end
end