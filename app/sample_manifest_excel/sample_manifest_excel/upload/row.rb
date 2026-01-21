# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    ##
    # A Row relates to a row in a sample manifest spreadsheet.
    # Each Row relates to a sample
    # Required fields:
    # *number: Number of the row which is used for error tracking
    # *data: An array of sample data
    # *columns: The columns which relate to the data.
    class Row # rubocop:todo Metrics/ClassLength
      include ActiveModel::Model
      include Converters

      attr_accessor :number, :data, :columns, :cache
      attr_reader :sanger_sample_id

      validates :number, presence: true, numericality: true
      validate :sanger_sample_id_exists?, if: :sanger_sample_id
      validates_presence_of :data, :columns
      validate :country_of_origin_has_correct_case,
               if: -> { data.present? && columns.present? && columns.names.include?('country_of_origin') }

      validate :i7_present
      # Ensure i7 column is not blank if it exists in the manifest
      def i7_present
        return unless columns.present? && data.present? && columns.names.include?('i7') && value('i7').blank?

        errors.add(:base, "#{row_title} i7 can't be blank")
      end

      validate :i5_present
      # Ensure i5 column is not blank if it exists in the manifest
      def i5_present
        return unless columns.present? && data.present? && columns.names.include?('i5') && value('i5').blank?

        errors.add(:base, "#{row_title} i5 can't be blank, putting “n/a” in i5 if only needs one set of tags")
      end

      delegate :present?, to: :sample, prefix: true
      delegate :aliquots, :asset, to: :manifest_asset

      ##
      # Finds a sample based on the sanger_sample_id column. Must exist for row to be valid.
      # Creates the specialised fields for updating the sample based on the passed columns
      def initialize(attributes = {})
        super
        @cache ||= SampleManifestAsset
        @sanger_sample_id ||= value(:sanger_sample_id).presence if columns.present? && data.present?
      end

      ##
      # Finds the data value for a particular column.
      # Offset by 1. Columns have numbers data is an array
      def at(col_num)
        val = data[col_num - 1]
        strip_all_blanks(val)
      end

      ##
      # Find a value based on a column name
      def value(key)
        column_number = columns.find_column_or_null(:name, key).number

        # column_number is -1 if no column found by this name (returns NullColumn object from find)
        return nil if column_number.negative?

        at(column_number)
      end

      def first?
        number == 1
      end

      ##
      # Used for errors
      def row_title
        "Row #{number} -"
      end

      def aliquot
        @aliquot ||= manifest_asset.aliquot
      end
      deprecate aliquot: 'Chromium manifests may have multiple aliquots. Please use aliquots instead.',
                deprecator: Rails.application.deprecators[:sequencescape]

      def metadata
        @metadata ||= sample.sample_metadata
      end

      def specialised_fields
        @specialised_fields ||= create_specialised_fields
      end

      ##
      # Updating the sample involves:
      # *Checking it is ok to update row
      # *Updating all of the specialised fields in the aliquot
      # *Updating the sample metadata
      # *Saving the asset, metadata and sample
      # rubocop:todo Metrics/MethodLength
      def update_sample(tag_group, override) # rubocop:todo Metrics/AbcSize
        return unless valid?

        @reuploaded = sample.updated_by_manifest

        if sample.updated_by_manifest && !override
          @sample_skipped = true
        else
          update_specialised_fields(tag_group)
          asset.save!
          update_metadata_fields
          metadata.save!
          sample.updated_by_manifest = true
          sample.empty_supplier_sample_name = false
          @sample_updated = sample.save
        end
      end

      # rubocop:enable Metrics/MethodLength

      def changed?
        (@sample_updated && sample.previous_changes.present?) || metadata.previous_changes.present? ||
          aliquots.any? { |a| a.previous_changes.present? }
      end

      def update_specialised_fields(tag_group)
        specialised_fields.each { |specialised_field| specialised_field.update(tag_group:) }
      end

      def update_metadata_fields
        columns.with_metadata_fields.each do |column|
          value = at(column.number)
          column.update_metadata(metadata, value) if value.present?
        end
      end

      ##
      # If it is a multiplexed library tube the aliquot is transferred
      # from the library tube to a multiplexed library tube and stated set to passed.
      def transfer_aliquot
        return unless valid?

        asset.external_library_creation_requests.each do |request|
          @aliquot_transferred = request.passed? || request.manifest_processed!
        end
      end

      def reuploaded?
        @reuploaded || false
      end

      def sample
        @sample ||= manifest_asset&.find_or_create_sample if sanger_sample_id.present? && !empty?
      end

      def sample_updated?
        @sample_updated || false
      end

      def sample_skipped_or_updated?
        @sample_skipped || sample_updated?
      end

      def sample_created?
        sample_updated? && !reuploaded?
      end

      def aliquot_transferred?
        @aliquot_transferred
      end

      def empty?
        # a row must have one of the primary column options
        primary_column_names = %w[supplier_name bioscan_supplier_name]

        # check the columns exist, are valid, and at least one of the primary column options are present
        unless columns.present? && columns.valid? &&
            primary_column_names.any? { |column_name| columns.names.include? column_name }
          return true
        end

        # it is mandatory to have a value in the primary column
        return true if primary_column_names.all? { |column_name| value(column_name).blank? }

        false
      end

      def labware
        sample.primary_receptacle.labware
      end

      def validate_sample
        check_sample_present
        sample_can_be_updated
        errors.empty?
      end

      private

      # The EBI country of origin values are case sensitive. This extra validation checks that the value
      # provided in the upload matches the allowed values with correct case.
      def country_of_origin_has_correct_case
        country_column = find_country_of_origin_column
        # If not found will be a NullColumn with number -1
        return unless valid_country_column?(country_column)

        value = at(country_column.number)
        return unless needs_country_of_origin_error?(value)

        add_country_of_origin_error(value)
      end

      def find_country_of_origin_column
        columns.find_column_or_null(:name, 'country_of_origin')
      end

      def valid_country_column?(country_column)
        country_column.number >= 0
      end

      def needs_country_of_origin_error?(value)
        # Skip the error creation if the value is blank. The column is mandatory by default and the mandatory column
        # validation will catch this scenario. And if the column is optional, then blank is acceptable.
        # Using exclude here (which is case sensitive) to check if country matches to Insdc EBI list of countries
        value.present? && Insdc::Country.options.exclude?(value)
      end

      # Format user friendly error message for country of origin value
      def add_country_of_origin_error(value)
        suggestion = Insdc::Country.options.find { |c| c.casecmp(value).zero? }
        message = "#{row_title} Country of Origin value '#{value}' does not match any allowed value " \
                  '(NB. case-sensitive).'
        message += " Did you mean '#{suggestion}'?" if suggestion
        errors.add(:base, message)
      end

      def manifest_asset
        return @manifest_asset if defined?(@manifest_asset)

        @manifest_asset = cache.find_by(sanger_sample_id:)
      end

      def sanger_sample_id_exists?
        return false if manifest_asset.present?

        errors.add(:base, "#{row_title} Cannot find sample manifest for Sanger ID: #{sanger_sample_id}")
      end

      def sample_can_be_updated
        return unless errors.empty?

        check_primary_receptacle
        check_specialised_fields
        check_sample_metadata
      end

      def check_primary_receptacle
        return if sample.primary_receptacle.present?

        errors.add(:base, "#{row_title} Does not have a primary receptacle.")
      end

      def check_specialised_fields
        return unless errors.empty?

        specialised_fields.each do |specialised_field|
          unless specialised_field.valid?
            errors.add(:base, "#{row_title} #{specialised_field.errors.full_messages.join(', ')}")
          end
        end
      end

      def check_sample_metadata
        # it has to be called here, otherwise metadata errors will not appear
        update_metadata_fields
        return if metadata.valid?

        errors.add(:base, "#{row_title} #{metadata.errors.full_messages.join(', ')}")
      end

      def check_sample_present
        return if sample_present?

        errors.add(:base, "#{row_title} Sample can't be blank.")
      end

      def create_specialised_fields
        return [] unless columns.present? && data.present? && sanger_sample_id.present?

        specialised_fields =
          columns.with_specialised_fields.map do |column|
            column.specialised_field.new(value: at(column.number), sample_manifest_asset: manifest_asset)
          end

        specialised_fields.tap { |fields| link_tag_groups_and_indexes(fields) }
      end

      # link fields together for tag groups and indexes
      def link_tag_groups_and_indexes(fields)
        indexed_fields = fields.index_by(&:class)
        fields.each { |field| field.link(indexed_fields) }
      end
    end
  end
end
