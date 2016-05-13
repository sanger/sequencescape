module SampleManifestExcel

  #ColumnList is a collection of columns

  class ColumnList

    include Enumerable

    attr_reader :columns

    #To create a column_list a hash with details of all columns is required. Each key is
    #a column name, each value is options for the column including heading, validation,
    #conditional formatting rules, etc.
    #An example of a hash is in file test/data/sample_manifest_excel/sample_manifest_all_columns.yml

    def initialize(columns = {})
      create_columns(columns)
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
      columns[key]
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

    def with_attributes
      columns.values.select { |column| column.attribute? }
    end

    def with_validations
      columns.values.select { |column| column.validation? }
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

    #Prepares columns to be added to the data worksheet. All argumens are not known to column list
    #(they are attributes of data worksheet, see also DataWorksheet#prepare_columns)

    def prepare_columns(first_row, last_row, styles, ranges)
      each {|k, column| column.prepare_with(first_row, last_row, styles, ranges)}
    end

    #Receives axlsx_worksheet as an argument and adds data validations and conditional
    #formattings for all columns on this axlsx_worksheet

    def add_validation_and_conditional_formatting(axlsx_worksheet)
      each {|k, column| column.add_validation_and_conditional_formatting(axlsx_worksheet)}
    end

  private

    #Creates columns from columns data (a hash)

    def create_columns(columns)
      columns.each do |k,v|
        add SampleManifestExcel::Column.new((v || {}).merge(name: k))
      end
      add_attributes
    end

    #Adds attributes to particular columns.
    #TO BE MOVED TO COLUMN CLASS

    def add_attributes
      find_by(:sanger_plate_id).attribute = {sanger_human_barcode: Proc.new { |sample| sample.wells.first.plate.sanger_human_barcode }} if columns[:sanger_plate_id]
      find_by(:well).attribute = {well: Proc.new { |sample| sample.wells.first.map.description }} if columns[:well]
      find_by(:sanger_sample_id).attribute = {sanger_sample_id: Proc.new { |sample| sample.sanger_sample_id }} if columns[:sanger_sample_id]
      find_by(:donor_id).attribute = {sanger_sample_id: Proc.new { |sample| sample.sanger_sample_id }} if columns[:donor_id]
      find_by(:donor_id_2).attribute = {sanger_sample_id: Proc.new { |sample| sample.sanger_sample_id }} if columns[:donor_id_2]
      find_by(:sanger_tube_id).attribute = {sanger_tube_id: Proc.new { |sample| sample.assets.first.sanger_human_barcode}} if columns[:sanger_tube_id]
    end

  end
end