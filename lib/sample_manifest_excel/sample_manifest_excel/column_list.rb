module SampleManifestExcel

  #ColumnList is a collection of columns

  class ColumnList

    include Enumerable

    attr_reader :columns

    #To create a column_list a hash with details of all columns is required. Each key is
    #a column name, each value is options for the column including heading, validation,
    #conditional formatting rules, etc.
    #An example of a hash is in file test/data/sample_manifest_excel/sample_manifest_all_columns.yml

    def initialize(columns = {}, conditional_formattings = {})
      create_columns(columns, conditional_formattings)
      yield self if block_given?
    end

    #Columns is a hash with a column name as a key and a column object as a value.

    def each(&block)
      columns.each(&block)
    end

    #Extracts headings from all columns

    def headings
      columns.values.collect(&:heading)
    end

    #Finds a column by name

    def find_by(key)
      columns[key] || columns[key.to_s]
    end

    #Extracts columns from a column list based on names (a list of columns names).
    #Returns a new column list that consists only of the columns named in names.

    def extract(names)
      ColumnList.new do |column_list|
        names.each do |name|
          column_list.add find_by(name)
        end
      end
    end

#QUESTION. The next four methods are not used in code anymore. But they are very handy in tests.
#Should I move them to some kind of 'helpers' file in tests? Or is it better just to change the tests?

    def with_validations
      columns.values.reject { |column| column.validation.empty? }
    end

    def with_unlocked
      columns.values.select { |column| column.unlocked? }
    end

    def with_conditional_formatting_rules
      columns.values.select { |column| column.conditional_formatting_rules?}
    end

    #Adds column to a column list, assigns a number to a column

    def add(column)
      return unless column.valid?
      columns[column.name] = column.set_number(next_number)
    end

    #Adds dupped column to a column list.

    def add_with_dup(column)
      add(column.dup)
    end

    #Returns a number of a next column

    def next_number
      columns.count+1
    end

    #Columns is a hash with a column name as a key and a column object as a value.

    def columns
      @columns ||= {}
    end

    #Prepares columns to be added to the data worksheet. All arguments are not known to column list
    #(they are attributes of data worksheet, see also DataWorksheet#prepare_columns)

    def update(first_row, last_row, ranges, workbook)
       each {|k, column| column.update(first_row, last_row, ranges, workbook)}
    end

    #Receives axlsx_worksheet as an argument and adds data validations and conditional
    #formattings for all columns on this axlsx_worksheet

    def add_validation_and_conditional_formatting(axlsx_worksheet)
      each {|k, column| column.add_validation_and_conditional_formatting(axlsx_worksheet)}
    end

  private

    #Creates columns from columns data (a hash)

    def create_columns(columns, conditional_formattings)
      columns.each do |k,v|
        begin
          add SampleManifestExcel::Column.new(v.combine_by_key(conditional_formattings, :conditional_formattings).merge(name: k))
        rescue TypeError => e 
          puts "column can't be created for #{k}: #{e.message}"
        end
      end
    end

  end
end