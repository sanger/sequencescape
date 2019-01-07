# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    module Processor
      ##
      # Uploads will be processed slightly differently based on the manifest type.
      class Base
        include ActiveModel::Model
        include SequencescapeExcel::SubclassChecker

        subclasses? :one_d_tube, :multiplexed_library_tube, :library_tube, :plate, modual: to_s.deconstantize

        attr_reader :upload
        validates_presence_of :upload
        validate :check_upload_type
        validate :check_for_barcodes_unique

        def initialize(upload)
          @upload = upload
        end

        ##
        # If the processor is valid the samples and manifest are updated.
        def run(tag_group)
          return unless valid?

          update_samples(tag_group)
          update_sample_manifest
        end

        def update_samples(tag_group)
          upload.rows.each do |row|
            row.update_sample(tag_group, upload.override)
          end
        end

        def samples_updated?
          upload.rows.all?(&:sample_skipped_or_updated?) || log_error_and_return_false('Could not update samples')
        end

        def processed?
          @processed ||= samples_updated? && sample_manifest_updated?
        end

        ##
        # Override the sample manifest with the raw uploaded data.
        def update_sample_manifest
          @sample_manifest_updated = upload.sample_manifest.update(uploaded: upload.file)
        end

        def sample_manifest_updated?
          @sample_manifest_updated
        end

        def type
          self.class.to_s
        end

        private

        # Log post processing checks and fail
        def log_error_and_return_false(message)
          upload.errors.add(:base, message)
          false
        end

        def check_upload_type
          return if upload.instance_of?(SampleManifestExcel::Upload::Base)

          errors.add(:base, 'This is not a recognised upload type.')
        end

        # For tube manifests barcodes (sanger tube id column) should be different in each row in the upload.
        # Uniqueness of foreign barcodes in the database is checked in the specialised field sanger_tube_id.
        def check_for_barcodes_unique
          return unless any_duplicate_barcodes?

          errors.add(:base, 'Duplicate barcodes detected, the barcode must be unique for each tube.')
        end

        def any_duplicate_barcodes?
          return false unless upload.respond_to?('rows')

          unique_bcs = []
          upload.rows.each do |row|
            next if row.columns.blank? || row.data.blank?

            col_num = row.columns.find_column_or_null(:name, 'sanger_tube_id').number
            next unless col_num.present? && col_num.positive?

            curr_bc = row.data[col_num - 1]
            return true if unique_bcs.include?(curr_bc)

            unique_bcs << curr_bc
          end
          false
        end
      end
    end
  end
end
