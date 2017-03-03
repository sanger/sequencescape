module SampleManifestExcel

  class Upload
    include ActiveModel::Validations

    attr_reader :spreadsheet, :columns, :start_row, :sanger_sample_id_column

    validates_presence_of :sanger_sample_id_column
    validate :check_columns
    validate :check_tags

    def initialize(filename, column_list, start_row)
      @start_row = start_row
      @spreadsheet = Roo::Spreadsheet.open(filename).sheet(0)
      @columns = column_list.extract(spreadsheet.row(start_row))
      @sanger_sample_id_column = columns.find_by(:name, :sanger_sample_id)
    end

  private

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
