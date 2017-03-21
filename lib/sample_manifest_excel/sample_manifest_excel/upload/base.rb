module SampleManifestExcel
  module Upload
    class Base
      include ActiveModel::Model

      attr_accessor :filename, :column_list, :start_row

      attr_reader :spreadsheet, :columns, :sanger_sample_id_column, :rows, :sample_manifest, :data

      validates_presence_of :start_row, :sanger_sample_id_column, :sample_manifest
      validate :check_columns, :check_tags, :check_rows

      def initialize(attributes = {})
        super
        @data = Data.new(filename, start_row)
        @columns = column_list.extract(data.header_row)
        @sanger_sample_id_column = columns.find_by(:name, :sanger_sample_id)
        @rows = Rows.new(data, columns)
        @sample_manifest = get_sample_manifest
      end

      def inspect
        "<#{self.class}: @filename=#{filename}, @columns=#{columns.inspect}, @start_row=#{start_row}, @sanger_sample_id_column=#{sanger_sample_id_column}, @data=#{data.inspect}>"
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
        sample = Sample.find_by(id: data.cell(1, sanger_sample_id_column.number).to_i)
        sample.sample_manifest if sample.present?
      end

      def update_sample_manifest
        sample_manifest.update_attributes(uploaded: File.open(filename))
      end

    private

      def check_rows
        unless rows.valid?
          rows.errors.each do |key, value|
            errors.add key, value
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
          combinations = data.column(tag_oligo_column.number).zip(data.column(tag2_oligo_column.number))
          errors.add(:tags_combinations, 'are not unique') unless combinations.length == combinations.uniq.length
        end
      end
    end
  end
end