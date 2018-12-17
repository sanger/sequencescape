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
    class Row
      include ActiveModel::Model

      attr_accessor :number, :data, :columns
      attr_reader :sanger_sample_id

      validates :number, presence: true, numericality: true
      validates_presence_of :data, :columns
      validate :check_sample_present
      validate :sample_can_be_updated
      delegate :present?, to: :sample, prefix: true

      ##
      # Finds a sample based on the sanger_sample_id column. Must exist for row to be valid.
      # Creates the specialised fields for updating the sample based on the passed columns
      def initialize(attributes = {})
        super
        @sanger_sample_id ||= value(:sanger_sample_id) if columns.present? && data.present?
        @specialised_fields = create_specialised_fields if sanger_sample_id.present?
        link_tag_groups_and_indexes
      end

      ##
      # Finds the data value for a particular column.
      # Offset by 1. Columns have numbers data is an array
      def at(col_num)
        data[col_num - 1]
      end

      ##
      # Find a value based on a column name
      def value(key)
        at(columns.find_column_or_null(:name, key).number)
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
        @aliquot ||= sample.aliquots.first
      end

      def metadata
        @metadata ||= sample.sample_metadata
      end

      def specialised_fields
        @specialised_fields ||= []
      end

      ##
      # Updating the sample involves:
      # *Checking it is ok to update row
      # *Updating all of the specialised fields in the aliquot
      # *Updating the sample metadata
      # *Saving the aliquot, metadata and sample
      def update_sample(tag_group, override)
        return unless valid?

        if sample.updated_by_manifest && !override
          @sample_skipped = true
        else
          update_specialised_fields(tag_group)
          aliquot.save!
          metadata.save!
          sample.updated_by_manifest = true
          @sample_updated = sample.save
        end
      end

      def changed?
        @sample_updated && sample.previous_changes.present? || metadata.previous_changes.present? || aliquot.previous_changes.present?
      end

      def update_specialised_fields(tag_group)
        specialised_fields.each do |specialised_field|
          specialised_field.update(aliquot: aliquot, tag_group: tag_group)
        end
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

        sample.primary_receptacle.external_library_creation_requests.each do |request|
          @reuploaded ||= request.passed?
          @aliquot_transferred = request.passed? || request.manifest_processed!
        end
      end

      def reuploaded?
        @reuploaded || false
      end

      def sample
        @sample ||= find_or_create_sample if sanger_sample_id.present? && !empty?
      end

      def sample_updated?
        @sample_updated || false
      end

      def sample_skipped_or_updated?
        @sample_skipped || sample_updated?
      end

      def aliquot_transferred?
        @aliquot_transferred
      end

      def empty?
        primary_column = 'supplier_name'
        return true unless columns.present? && columns.valid? && columns.names.include?(primary_column)

        value(primary_column).blank?
      end

      def labware
        sample.primary_receptacle.labware
      end

      private

      def find_or_create_sample
        sample = Sample.find_by(sanger_sample_id: sanger_sample_id)
        sample.presence || create_sample
      end

      def create_sample
        manifest_asset = SampleManifestAsset.find_by(sanger_sample_id: sanger_sample_id)
        if manifest_asset.present?
          manifest_asset.sample_manifest.create_sample_and_aliquot(sanger_sample_id, manifest_asset.asset)
        else
          errors.add(:base, "#{row_title} Cannot find sample manifest for Sanger ID: #{sanger_sample_id}")
          nil
        end
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
          errors.add(:base, "#{row_title} #{specialised_field.errors.full_messages.join(', ')}") unless specialised_field.valid?
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
        return unless columns.present? && data.present? && sample.present?

        [].tap do |specialised_fields|
          columns.with_specialised_fields.each do |column|
            specialised_fields << column.specialised_field.new(value: at(column.number), sample: sample)
          end
        end
      end

      # link fields together for tag groups and indexes
      def link_tag_groups_and_indexes
        sf_tag_index = specialised_fields.detect { |sf| sf.instance_of? SequencescapeExcel::SpecialisedField::TagIndex }
        return if sf_tag_index.blank?

        sf_tag_index.sf_tag_group = specialised_fields.detect { |sf| sf.instance_of? SequencescapeExcel::SpecialisedField::TagGroup }

        sf_tag2_index = specialised_fields.detect { |sf| sf.instance_of? SequencescapeExcel::SpecialisedField::Tag2Index }
        return if sf_tag2_index.blank?

        sf_tag2_index.sf_tag2_group = specialised_fields.detect { |sf| sf.instance_of? SequencescapeExcel::SpecialisedField::Tag2Group }
      end
    end
  end
end
