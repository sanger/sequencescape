module SampleManifestExcel

  class Upload
    include ActiveModel::Model

    attr_accessor :filename, :column_list, :start_row

    attr_reader :spreadsheet, :columns, :sanger_sample_id_column

    validates_presence_of :sanger_sample_id_column
    validate :check_columns, :check_tags, :check_rows

    def initialize(attributes = {})
      super
      @spreadsheet = Roo::Spreadsheet.open(filename).sheet(0)
      @columns = column_list.extract(spreadsheet.row(start_row))
      @sanger_sample_id_column = columns.find_by(:name, :sanger_sample_id)
    end

    def inspect
      "<#{self.class}: @filename=#{filename}, @columns=#{columns.inspect}, @start_row=#{start_row}, @sanger_sample_id_column=#{sanger_sample_id_column}, @spreadsheet=#{spreadsheet.info}, @specialised_fields=#{specialised_fields.inspect}>"
    end

  private

    def check_rows
      if errors.empty?
        spreadsheet.drop(start_row).each.with_index(1) do |r, i|
          row = Row.new(number: i, data: r, columns: columns)
          unless row.valid?
            errors.add(:base, row.errors.full_messages)
          end
        end
      end
    end

    def check_columns
      unless columns.valid?
        columns.errors.each do |key, value|
          errors.add key, value
        end
      end
    end

    def check_tags
      tag_oligo_column = columns.find_by(:name, :tag_oligo)
      tag2_oligo_column = columns.find_by(:name, :tag2_oligo)
      if tag_oligo_column.present? & tag2_oligo_column.present?
        combinations = spreadsheet.column(tag_oligo_column.number).drop(start_row).zip(spreadsheet.column(tag2_oligo_column.number).drop(start_row))
        errors.add(:tags_combinations, 'are not unique') unless combinations.length == combinations.uniq.length
      end
    end
  end
end
