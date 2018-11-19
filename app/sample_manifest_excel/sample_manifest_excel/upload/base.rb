# frozen_string_literal: true

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

      attr_accessor :filename, :column_list, :start_row, :override

      attr_reader :spreadsheet, :columns, :sanger_sample_id_column, :rows, :sample_manifest, :data, :processor

      validates_presence_of :start_row, :sanger_sample_id_column, :sample_manifest
      validate :check_columns, :check_processor, :check_rows
      validate :check_processor, if: :processor?

      delegate :processed?, to: :processor
      delegate :data_at, to: :rows

      def initialize(attributes = {})
        super
        @data = Upload::Data.new(filename, start_row)
        @columns = column_list.extract(data.header_row || [])
        @sanger_sample_id_column = columns.find_by(:name, :sanger_sample_id)
        @rows = Upload::Rows.new(data, columns)
        @sample_manifest = derive_sample_manifest
        @override = override || false
        @processor = create_processor
      end

      def inspect
        "<#{self.class}: @filename=#{filename}, @columns=#{columns.inspect}, @start_row=#{start_row}, @sanger_sample_id_column=#{sanger_sample_id_column}, @data=#{data.inspect}>"
      end

      ##
      # The sample manifest is retrieved by taking the sample from the first row and retrieving
      # its sample manifest.
      # If it can't be found the upload will fail.
      def derive_sample_manifest
        return unless start_row.present? && sanger_sample_id_column.present?
        sanger_sample_id = data.cell(1, sanger_sample_id_column.number)
        sample = Sample.find_by(sanger_sample_id: sanger_sample_id)
        if sample.present?
          return sample.sample_manifest
        else
          return SampleManifestAsset.where(sanger_sample_id: sanger_sample_id).first&.sample_manifest
        end
      end

      ##
      # An upload can only be processed if the upload is valid.
      # Processing involves updating the sample manifest and all of its associated samples.
      def process(tag_group)
        ActiveRecord::Base.transaction do
          sample_manifest.last_errors = nil
          sample_manifest.start!
          processor.run(tag_group)
          return true if processed?

          # One of out post processing checks failed, something went wrong, so we
          # roll everything back
          raise ActiveRecord::Rollback
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

      def fail
        # If we've failed, do not update the manifest file, trying to do so
        # causes exceptions
        sample_manifest.association(:uploaded_document).reset
        sample_manifest.fail!
      end

      private

      def create_processor
        if sample_manifest.present?
          case sample_manifest.asset_type
          when '1dtube'
            Upload::Processor::OneDTube.new(self)
          when 'library'
            Upload::Processor::LibraryTube.new(self)
          when 'multiplexed_library'
            Upload::Processor::MultiplexedLibraryTube.new(self)
          when 'plate'
            Upload::Processor::Plate.new(self)
          end
        else
          SequencescapeExcel::NullObjects::NullProcessor.new(self)
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
        return if object.valid?

        object.errors.each do |key, value|
          errors.add key, value
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
