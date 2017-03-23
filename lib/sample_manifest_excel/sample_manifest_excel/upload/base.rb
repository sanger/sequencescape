module SampleManifestExcel
  module Upload
    class Base
      include ActiveModel::Model

      attr_accessor :filename, :column_list, :start_row

      attr_reader :spreadsheet, :columns, :sanger_sample_id_column, :rows, :sample_manifest, :data, :processor

      validates_presence_of :start_row, :sanger_sample_id_column, :sample_manifest
      validate :check_columns, :check_processor, :check_rows
      validate :check_processor, if: 'processor.present?'

      def initialize(attributes = {})
        super
        @data = Data.new(filename, start_row)
        @columns = column_list.extract(data.header_row)
        @sanger_sample_id_column = columns.find_by(:name, :sanger_sample_id)
        @rows = Rows.new(data, columns)
        @sample_manifest = get_sample_manifest
        @processor = create_processor
      end

      def inspect
        "<#{self.class}: @filename=#{filename}, @columns=#{columns.inspect}, @start_row=#{start_row}, @sanger_sample_id_column=#{sanger_sample_id_column}, @data=#{data.inspect}>"
      end

      def get_sample_manifest
        return unless start_row.present? && sanger_sample_id_column.present?
        sample = Sample.find_by(id: data.cell(1, sanger_sample_id_column.number).to_i)
        sample.sample_manifest if sample.present?
      end

      def process(tag_group)
        processor.run(tag_group)
      end

    private

      def create_processor
        if sample_manifest.present?
          case sample_manifest.asset_type
          when '1dtube'
            Processor::OneDTube.new(self)
          when 'multiplexed_library'
            Processor::MultiplexedLibraryTube.new(self)
          end
        end
      end

      def check_rows
        check_object(rows)
      end

      def check_columns
        check_object(columns)
      end

      def check_processor
        check_object(processor)
      end

      def check_object(object)
        unless object.valid?
          object.errors.each do |key, value|
            errors.add key, value
          end
        end
      end
    end
  end
end
