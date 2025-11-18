# frozen_string_literal: true

module SampleManifestExcel
  # Handles the processing of uploaded manifests, extraction of information
  # and the updating of samples and their assets in Sequencescape
  module Upload
    ##
    # An upload will
    # *Find the start row based on the Sanger Sample Id column header cell
    # *Create a Data object based on the file.
    # *Extract the columns based on the headings in the spreadsheet
    # *Find the sanger sample id column
    # *Create some Rows
    # *Retrieve the sample manifest
    # *Create a processor based on the sample manifest
    # The Upload is only valid if the file, columns, sample manifest and processor are valid.
    class Base # rubocop:todo Metrics/ClassLength
      include ActiveModel::Model

      attr_accessor :file, :column_list, :start_row, :override

      # rubocop:todo Layout/LineLength
      attr_reader :spreadsheet, :columns, :sanger_sample_id_column, :rows, :sample_manifest, :data, :processor, :cache # TODO: probably shouldn't add the cache here, do it another way

      # rubocop:enable Layout/LineLength

      validates_presence_of :start_row, :sanger_sample_id_column, :sample_manifest
      validate :check_data

      # If the file isn't valid, and hasn't been read, then don't the contents
      # it will just appear to be empty, which is confusing.
      validate :check_columns, :check_processor, :check_rows, if: :data_valid?
      validate :check_processor, if: :processor?

      delegate :processed?, to: :processor
      delegate :data_at, to: :rows
      delegate :study, to: :sample_manifest, allow_nil: true

      def initialize(attributes = {}) # rubocop:todo Metrics/AbcSize
        super
        @data = Upload::Data.new(file)
        @start_row = @data.start_row
        @columns = column_list.extract(data.header_row.reject(&:blank?) || [])
        @sanger_sample_id_column = columns.find_by(:name, :sanger_sample_id)
        @cache = Cache.new(self)
        @rows = Upload::Rows.new(data, columns, @cache)
        @sample_manifest = derive_sample_manifest
        @override = override || false
        @processor = create_processor
      end

      def inspect
        # rubocop:todo Layout/LineLength
        "<#{self.class}: @file=#{file}, @columns=#{columns.inspect}, @start_row=#{start_row}, @sanger_sample_id_column=#{sanger_sample_id_column}, @data=#{data.inspect}>"
        # rubocop:enable Layout/LineLength
      end

      ##
      # The sample manifest is retrieved by taking the sanger sample id from the first row and retrieving
      # its sample manifest.
      # If it can't be found the upload will fail.
      def derive_sample_manifest
        return unless start_row.present? && sanger_sample_id_column.present?

        sanger_sample_id = data.cell(1, sanger_sample_id_column.number)
        SampleManifestAsset.find_by(sanger_sample_id:)&.sample_manifest ||
          Sample.find_by(sanger_sample_id:)&.sample_manifest
      end

      ##
      # An upload can only be processed if the upload is valid.
      # Processing involves updating the sample manifest and all of its associated samples.
      def process(tag_group)
        # Temporarily disable accessioning until we invoke it explicitly
        # If we don't do this, then any accidental triggering of sample
        # saves will result in duplicate accessions
        Sample::Current.processing_manifest = true
        sample_manifest.last_errors = nil
        @cache.populate!
        processor.run(tag_group)

        processed?
      ensure
        Sample::Current.processing_manifest = false
      end

      def data_at(column_name) # rubocop:todo Lint/DuplicateMethods
        required_column = columns.find_by(:name, column_name)
        rows.data_at(required_column.number) if required_column.present?
      end

      def broadcast_sample_manifest_updated_event(user)
        # Send to event warehouse
        sample_manifest.updated_broadcast_event(user, changed_samples.map(&:id))

        # Log legacy events: Show on history page, and may be used by reports.
        # We can get rid of these when:
        # - History page is updated with event warehouse viewer
        # - We've confirmed that no external reports use these events
        changed_samples.each { |sample| sample.handle_update_event(user) }
        changed_labware.each { |labware| labware.events.updated_using_sample_manifest!(user) }
      end

      def trigger_accessioning
        accession_status_group = Accession::StatusGroup.new(accession_group: nil)
        changed_samples.each { |sample| sample.accession(accession_status_group) }
      rescue AccessionService::AccessioningDisabledError, AccessionService::AccessionValidationFailed => e
        Rails.logger.warn "#{e.message} Skipping accessioning for changed samples."
      end

      # If samples have been created, and it's not a library plate/tube, register a stock_resource record in the MLWH
      def register_stock_resources
        stock_receptacles_to_be_registered.each(&:register_stock!)
      end

      def fail
        # If we've failed, do not update the manifest file, trying to do so
        # causes exceptions
        sample_manifest.association(:uploaded_document).reset
        # Errs here because sample_manifest.samples is a collection that's not empty in Rails 6.1,
        # but is empty in Rails 5.0. Therefore, reloaded the samples.
        sample_manifest.samples.reload
        sample_manifest.fail!
      end

      private

      def create_processor # rubocop:todo Metrics/MethodLength
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
          Upload::Processor::TubeRack.new(self)
        else
          SequencescapeExcel::NullObjects::NullProcessor.new(self)
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

        # In Rails 6.1 object.errors returns ActiveModel::Errors, in Rails 6.0 it returns a Hash
        if object.errors.is_a?(ActiveModel::Errors)
          object.errors.each { |error| errors.add error.attribute, error.message }
        else
          object.errors.each { |key, value| errors.add key, value }
        end
      end

      def processor?
        processor.present?
      end

      def changed_samples
        @changed_samples ||= rows.select(&:changed?).map(&:sample)
      end

      def changed_labware
        @changed_labware ||= rows.select(&:changed?).reduce(Set.new) { |set, row| set << row.labware }
      end

      def stock_receptacles_to_be_registered
        return [] unless sample_manifest.core_behaviour.stocks?

        @stock_receptacles_to_be_registered ||= rows.select(&:sample_created?).map(&:asset)
      end
    end
  end
end
