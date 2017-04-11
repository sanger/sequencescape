module SampleManifestExcel
  # A collection of columns
  class ColumnList
    include Enumerable
    include Comparable

    attr_reader :columns

    delegate :values, :keys, to: :columns

    ##
    # To create a column_list a hash with details of all columns is required. Each key is
    # a column name, each value is options for the column including heading, validation,
    # conditional formatting rules, etc.
    # for each column a new Column object is created.
    # Each conditional formatting for the column is combined with its conditional formatting in the list.
    # If the column is not valid an error is returned.
    def initialize(columns = {}, conditional_formattings = {})
      create_columns(columns, conditional_formattings)
      yield self if block_given?
    end

    ##
    # Columns is a hash with a column name as a key and a column object as a value.
    def each(&block)
      columns.each(&block)
    end

    ##
    # Extracts headings from all columns
    def headings
      columns.values.collect(&:heading)
    end

    ##
    # Finds a column by by it's key either by string or symbol.
    def find_by(key)
      columns[key] || columns[key.to_s]
    end

    ##
    # Extracts columns from a column list based on names (a list of columns names).
    # Returns a new column list that consists only of the columns named in names.
    def extract(names)
      ColumnList.new do |column_list|
        names.each do |name|
          column_list.add_with_dup find_by(name)
        end
      end
    end

    ##
    # Adds column to a column list, assigns a number to a column
    def add(column)
      return unless column.valid?
      columns[column.name] = column.set_number(next_number)
    end

    ##
    # Adds dupped column to a column list.
    def add_with_dup(column)
      add(column.dup)
    end

    ##
    # Returns a number of a next column based on the number of columns
    # that already exist in the list
    def next_number
      columns.count + 1
    end

    # Defaults to an empty hash
    def columns
      @columns ||= {}
    end

    def copy(key, column)
      columns[key] = column.dup
    end

    ##
    # A forwarding method - Update each column in the list of columns.
    def update(first_row, last_row, ranges, worksheet)
       each { |_k, column| column.update(first_row, last_row, ranges, worksheet) }
    end

    def <=>(other)
      return unless other.is_a?(self.class)
      columns <=> other.columns
    end

    def initialize_dup(source)
      reset!
      create_columns(source.columns, nil)
      super
    end

  private

    def reset!
      @columns = {}
    end

    def create_columns(columns, conditional_formattings)
      columns.each do |k, v|
        begin
          if v.kind_of?(Hash)
            add SampleManifestExcel::Column.new(SampleManifestExcel::Column.build_arguments(v, k, conditional_formattings))
          else
            copy k, v
          end
        rescue TypeError => e
          puts "column can't be created for #{k}: #{e.message}"
        end
      end
    end
  end
end
