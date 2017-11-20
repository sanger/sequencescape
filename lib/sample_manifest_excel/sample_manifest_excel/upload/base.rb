module SampleManifestExcel
  module Upload
    ##
    # An upload will:
    # *Create a Data object based on the filename.
    # *Extract the columns based on the headings in the spreadsheet
    # *Find the sanger sample id column
    # *Create some Rows
    # *Retrieve the sample manifest
    # *Create a processor based on the sample manifest
    # The Upload is only valid if the file, columns, sample manifest and processor are valid.
    class Base
      include ActiveModel::Model

      attr_accessor :filename, :column_list, :start_row

      attr_reader :spreadsheet, :columns, :sanger_sample_id_column, :rows, :sample_manifest, :data, :processor

      validates_presence_of :start_row, :sanger_sample_id_column, :sample_manifest
      validate :check_columns, :check_processor, :check_rows
      validate :check_processor, if: :processor?

      delegate :processed?, to: :processor
      delegate :data_at, to: :rows

      def initialize(attributes = {})
        super
        @data = Data.new(filename, start_row)
        @columns = column_list.extract(data.header_row || [])
        @sanger_sample_id_column = columns.find_by(:name, :sanger_sample_id)
        @rows = Rows.new(data, columns)
        @sample_manifest = get_sample_manifest
        @processor = create_processor
        @reuploaded = @sample_manifest.completed? if sample_manifest.present?
      end

      def inspect
        "<#{self.class}: @filename=#{filename}, @columns=#{columns.inspect}, @start_row=#{start_row}, @sanger_sample_id_column=#{sanger_sample_id_column}, @data=#{data.inspect}>"
      end

      ##
      # The sample manifest is retrieved by taking the sample from the first row and retrieving
      # its sample manifest.
      # If it can't be found the upload will fail.
      def get_sample_manifest
        return unless start_row.present? && sanger_sample_id_column.present?
        sample = Sample.find_by(sanger_sample_id: data.cell(1, sanger_sample_id_column.number))
        sample.sample_manifest if sample.present?
      end

      ##
      # An upload can only be processed if the upload is valid.
      # Processing involves updating the sample manifest and all of its associated samples.
      def process(tag_group)
        ActiveRecord::Base.transaction do
          sample_manifest.last_errors = nil
          sample_manifest.start!
          processor.run(tag_group)
        end
      end

      def data_at(column_name)
        required_column = columns.find_by(:name, column_name)
        rows.data_at(required_column.number) if required_column.present?
      end

      def broadcast_sample_manifest_updated_event(user)
        sample_manifest.updated_broadcast_event(user, samples_to_be_broadcasted)
      end

      def complete
        sample_manifest.finished!
      end

      def reuploaded?
        @reuploaded
      end

      private

      def create_processor
        if sample_manifest.present?
          case sample_manifest.asset_type
          when '1dtube'
            Processor::OneDTube.new(self)
          when 'library'
            Processor::LibraryTube.new(self)
          when 'multiplexed_library'
            Processor::MultiplexedLibraryTube.new(self)
          end
        else
          SampleManifestExcel::NullProcessor.new(self)
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

      def processor?
        processor.present?
      end

      def samples_to_be_broadcasted
        rows.map { |row| row.sample.id }
      end
    end
  end
end
