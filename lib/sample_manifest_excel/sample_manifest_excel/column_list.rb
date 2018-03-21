module SampleManifestExcel
  # A collection of columns
  class ColumnList
    include List

    list_for :columns, keys: [:name, :heading, :number]

    include ActiveModel::Validations

    validates_presence_of :columns
    validate :check_nil_keys

    ##
    # To create a column_list a hash with details of all columns is required. Each key is
    # a column name, each value is options for the column including heading, validation,
    # conditional formatting rules, etc.
    # for each column a new Column object is created.
    # Each conditional formatting for the column is combined with its conditional formatting in the list.
    # If the column is not valid an error is returned.
    def initialize(columns = {}, conditional_formattings = {})
      create_columns(columns || {}, conditional_formattings)
      yield self if block_given?
    end

    def column_values(replacements = {})
      replacements.each do |k, v|
        find(k).value = v
      end
      columns.collect(&:value)
    end

    ##
    # Extracts columns from a column list based on names (a list of columns names).
    # Returns a new column list that consists only of the columns named in names.
    def extract(keys)
      ColumnList.new do |column_list|
        keys.each do |key|
          column = find(key)
          if column.present?
            column_list.add_with_number(column.dup, column_list)
          else
            column_list.bad_keys << key
          end
        end
      end
    end

    def except(key)
      keys = names.dup
      keys.delete(key.to_s)
      extract(keys)
    end

    def with(key)
      add_with_number(Column.new(name: key, heading: key.to_s))
    end

    def bad_keys
      @bad_keys ||= []
    end

    def add_with_number(column, column_list = nil)
      add column.set_number((column_list || self).next_number)
      self
    end

    ##
    # Returns a number of a next column based on the number of columns
    # that already exist in the list
    def next_number
      columns.count + 1
    end

    ##
    # A forwarding method - Update each column in the list of columns.
    def update(first_row, last_row, ranges, worksheet)
      each { |column| column.update(first_row, last_row, ranges, worksheet) }
    end

    def initialize_dup(source)
      reset!
      create_columns(source.columns, nil)
      super
    end

    def find_by_or_null(key, value)
      find_by(key, value) || SampleManifestExcel::NullColumn.new
    end

    def with_specialised_fields
      select(&:specialised_field?)
    end

    def with_metadata_fields
      select(&:metadata_field?)
    end

    private

    # You can add a hash of columns, a hash of attributes or an array of columns.
    # If it is a hash of columns there is an assumption that a copy is being created.
    def create_columns(columns, conditional_formattings)
      columns.each do |k, v|
        begin
          add_with_number(if v.is_a?(Hash)
                            SampleManifestExcel::Column.new(SampleManifestExcel::Column.build_arguments(v, k, conditional_formattings))
                          else
                            k.dup
                          end, self)
        rescue TypeError => e
          Rails.logger.error("column can't be created for #{k}: #{e.message}")
        end
      end
    end

    def check_nil_keys
      if bad_keys.any?
        errors.add(:columns, "#{bad_keys.join(',')} are not valid.")
      end
    end
  end
end
