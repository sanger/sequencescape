module SampleManifestExcel

  class Upload
    include ActiveModel::Model

    attr_accessor :filename, :column_list, :start_row, :user

    attr_reader :spreadsheet, :columns, :sanger_sample_id_column, :rows, :sample_manifest

    validates_presence_of :sanger_sample_id_column, :sample_manifest, :user
    validate :check_columns, :check_tags, :check_rows

    def initialize(attributes = {})
      super
      @spreadsheet = Roo::Spreadsheet.open(filename).sheet(0)
      @columns = column_list.extract(spreadsheet.row(start_row))
      @sanger_sample_id_column = columns.find_by(:name, :sanger_sample_id)
      @rows = []
      @sample_manifest = get_sample_manifest
    end

    def inspect
      "<#{self.class}: @filename=#{filename}, @columns=#{columns.inspect}, @start_row=#{start_row}, @sanger_sample_id_column=#{sanger_sample_id_column}, @spreadsheet=#{spreadsheet.info}>"
    end

    def update_samples(tag_group)
      if valid?
        rows.each do |row|
          row.update_sample(tag_group)
        end
      end
    end

    def get_sample_manifest
      return unless start_row.present? && sanger_sample_id_column.present?
      sample = Sample.find_by(id: spreadsheet.cell(start_row + 1, sanger_sample_id_column.number).to_i)
      sample.sample_manifest if sample.present?
    end

    def update_sample_manifest
      sample_manifest.update_attributes(uploaded: File.open(filename))
    end

  private

    def check_rows
      if errors.empty?
        spreadsheet.drop(start_row).each.with_index(1) do |r, i|
          row = Row.new(number: i, data: r, columns: columns)
          unless row.valid?
            errors.add(:base, row.errors.full_messages)
          end
          rows << row
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
