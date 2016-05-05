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

    def with_validations
      columns.values.select { |column| column.validation? }
    end

    def with_unlocked
      columns.values.select { |column| column.unlocked? }
    end

    def with_cf_rules
      columns.values.select { |column| column.cf_rules?}
    end

    def add(column)
      return unless column.valid?
      columns[column.name] = column.set_number(next_number)
    end

    def add_with_dup(column)
      add(column.dup)
    end

    def next_number
      columns.count+1
    end

    def columns
      @columns ||= {}
    end

    def add_references(first_row, last_row)
      each {|k, column| column.add_reference(first_row, last_row)}
      self
    end

    def unlock(n)
      with_unlocked.each {|column| column.unlocked = n}
      self
    end

    def prepare_validations(ranges)
      with_validations.each do |column|
        range = ranges.find_by(column.range_name)
        column.prepare_validation(range)
      end
      self
    end

    def prepare_conditional_formatting_rules(styles, ranges)
      add_conditional_formatting_for_empty_cells
      with_cf_rules.each do |column|
        range = ranges.find_by(column.range_name) if column.validation?
        column.prepare_conditional_formatting_rules(styles, range)
      end
      self
    end

  private

    def create_columns(columns)
      columns.each do |k,v|
        add SampleManifestExcel::Column.new((v || {}).merge(name: k))
      end
    end

    def add_conditional_formatting_for_empty_cells
      with_unlocked.each do |column|
        column.add_conditional_formatting_rules conditional_formatting_rules_for_empty_cells
      end
    end

    def conditional_formatting_rules_for_empty_cells
      @cf_rules_for_empty_cells ||= SampleManifestExcel::ConditionalFormattingRule.new ({'dxfId' => :empty_cell, 'priority' => 1, 'operator' => :equal, 'formula' => 'FALSE', 'type' => :cellIs, 'stopIfTrue' => true})
    end
  end
end