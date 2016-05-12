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

    def with_conditional_formatting_rules
      columns.values.select { |column| column.conditional_formatting_rules?}
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

    def prepare_columns(first_row, last_row, styles, ranges)
      each {|k, column| column.prepare_with(first_row, last_row, styles, ranges)}
    end

    def add_validation_and_conditional_formatting(axlsx_worksheet)
      each {|k, column| column.add_validation_and_conditional_formatting(axlsx_worksheet)}
    end

  private

    def create_columns(columns)
      columns.each do |k,v|
        add SampleManifestExcel::Column.new((v || {}).merge(name: k))
      end
      add_attributes
    end

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