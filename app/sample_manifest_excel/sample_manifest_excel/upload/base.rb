# frozen_string_literal: true

module SampleManifestExcel
  # Handles the processing of uploaded manifests, extraction of information
  # and the updating of samples and their assets in Sequencescape
  module Upload
    ##
    # An upload will:
    # *Create a Data object based on the file.
    # *Extract the columns based on the headings in the spreadsheet
    # *Find the sanger sample id column
    # *Create some Rows
    # *Retrieve the sample manifest
    # *Create a processor based on the sample manifest
    # The Upload is only valid if the file, columns, sample manifest and processor are valid.
    class Base
      include ActiveModel::Model

      attr_accessor :file, :column_list, :start_row, :override

      attr_reader :spreadsheet, :columns, :sanger_sample_id_column, :rows, :sample_manifest, :data, :processor

      validates_presence_of :start_row, :sanger_sample_id_column, :sample_manifest
      validate :check_data
      # If the file isn't valid, and hasn't been read, then don't the contents
      # it will just appear to be empty, which is confusing.
      validate :check_columns, :check_processor, :check_rows, if: :data_valid?
      validate :check_processor, if: :processor?
      # TODO: add validation steps for tube racks, if not previously uploaded: *** here, or in the processor? ***
      # 1. check rack barcodes are present and unique
      # 2. use microservice to check if scans are present for all barcodes
      # 3. use microservice to retrieve tube barcodes and cross-compare with manifest

      delegate :processed?, to: :processor
      delegate :data_at, to: :rows
      delegate :study, to: :sample_manifest, allow_nil: true

      def initialize(attributes = {})
        super
        @start_row = find_start_row
        @data = Upload::Data.new(file, start_row)
        @columns = column_list.extract(data.header_row.reject(&:blank?) || [])
        @sanger_sample_id_column = columns.find_by(:name, :sanger_sample_id)
        @cache = Cache.new(self)        # TODO: might want this to cache tube racks and racked tubes?
        @rows = Upload::Rows.new(data, columns, @cache)
        @sample_manifest = derive_sample_manifest
        @override = override || false
        @processor = create_processor
      end

      def inspect
        "<#{self.class}: @file=#{file}, @columns=#{columns.inspect}, @start_row=#{start_row}, @sanger_sample_id_column=#{sanger_sample_id_column}, @data=#{data.inspect}>"
      end

      ##
      # The sample manifest is retrieved by taking the sanger sample id from the first row and retrieving
      # its sample manifest.
      # If it can't be found the upload will fail.
      def derive_sample_manifest
        return unless start_row.present? && sanger_sample_id_column.present?

        sanger_sample_id = data.cell(1, sanger_sample_id_column.number)
        SampleManifestAsset.find_by(sanger_sample_id: sanger_sample_id)&.sample_manifest ||
          Sample.find_by(sanger_sample_id: sanger_sample_id)&.sample_manifest
      end

      ##
      # An upload can only be processed if the upload is valid.
      # Processing involves updating the sample manifest and all of its associated samples.
      def process(tag_group)
        ActiveRecord::Base.transaction do
          sample_manifest.last_errors = nil
          sample_manifest.start!
          @cache.populate!
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
        # Send to event warehouse
        sample_manifest.updated_broadcast_event(user, samples_to_be_broadcasted.map(&:id))
        # Log legacy events: Show on history page, and may be used by reports.
        # We can get rid of these when:
        # - History page is updates with event warehouse viewer
        # - We've confirmed that no external reports use these events
        samples_to_be_broadcasted.each { |sample| sample.handle_update_event(user) }
        labware_to_be_broadcasted.each { |labware| labware.events.updated_using_sample_manifest!(user) }
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
        case sample_manifest&.asset_type
        when '1dtube'
          Upload::Processor::OneDTube.new(self)
        when 'library'
          Upload::Processor::LibraryTube.new(self)
        when 'multiplexed_library'
          Upload::Processor::MultiplexedLibraryTube.new(self)
        when 'plate', 'library_plate'
          Upload::Processor::Plate.new(self)
        when 'tube_rack'
          Upload::Processor::TubeRackProcessor.new(self)
        else
          SequencescapeExcel::NullObjects::NullProcessor.new(self)
        end
      end

      def find_start_row
        opened_sheet = Roo::Spreadsheet.open(file).sheet(0)

        (0..opened_sheet.last_row).each do |row_num|
          opened_sheet.row(row_num).each do |cell_value|
            return row_num if cell_value == 'SANGER SAMPLE ID'
          end
        end
      end

      def data_valid?
        data.valid?
      end

      def check_data
        check_object(data)
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
        @samples_to_be_broadcasted ||= rows.select(&:changed?).map(&:sample)
      end

      def labware_to_be_broadcasted
        @labware_to_be_broadcasted ||= rows.select(&:changed?).reduce(Set.new) { |set, row| set << row.labware }
      end
    end
  end
end
