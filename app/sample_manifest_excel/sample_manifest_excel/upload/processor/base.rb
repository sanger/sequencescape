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

          # here, do Sanger Plate ID specialised field update first
          # run the validation beforehand as well
          return unless process_early_specialised_fields

          # then, find or create samples (take sample validation out from earlier)
          create_samples_if_not_present

          # then, run the sample validation that I took out earlier
          return unless samples_valid?

          # then, continue as normal
          update_samples_and_aliquots(tag_group)
          update_sample_manifest
        end

        def process_early_specialised_fields
          return false unless early_specialised_fields_valid?

          upload.rows.each { |row| row.update_specialised_fields(nil, true) }
          true
        end

        def early_specialised_fields_valid?
          upload.rows.each do |row|
            row.check_specialised_fields(true)

            next if row.errors.empty?

            upload.errors.add(:base, "Row #{row.number} - #{row.errors.full_messages.join(', ')}")
          end

          upload.errors.empty?
        end

        def create_samples_if_not_present
          upload.rows.each(&:sample)
        end

        def samples_valid?
          all_valid = true

          upload.rows.each do |row|
            unless row.validate_sample
              upload.errors.add(:base, "Row #{row.number} - #{row.errors.full_messages.join(', ')}")
              all_valid = false
            end
          end

          all_valid
        end

        def update_samples_and_aliquots(tag_group)
          upload.rows.each do |row|
            row.update_sample(tag_group, upload.override) # This is where the foreign barcode gets inserted
            substitutions << row.aliquot.substitution_hash if row.reuploaded?
          end
          update_downstream_aliquots unless no_substitutions?
        end

        def samples_updated?
          upload.rows.all?(&:sample_skipped_or_updated?) || log_error_and_return_false('Could not update samples')
        end

        def processed?
          samples_updated? && sample_manifest_updated? && aliquots_updated?
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

        def substitutions
          @substitutions ||= []
        end

        def downstream_aliquots_updated?
          @downstream_aliquots_updated
        end

        def aliquots_updated?
          downstream_aliquots_updated? || no_substitutions? ||
            log_error_and_return_false('Could not update tags in other assets.')
        end

        private

        def disable_match_expectation
          true
        end

        # if manifest is reuploaded, only aliquots, that are in 'fake' library tubes will be updated
        # actual aliquots in multiplexed library tube and other aliquots downstream are updated by this method
        # library updates all aliquots in one go, doing it row by row is inefficient and may trigger tag clash
        def update_downstream_aliquots
          substituter =
            TagSubstitution.new(
              substitutions: substitutions.compact,
              comment: 'Manifest updated',
              disable_clash_detection: true,
              disable_match_expectation: disable_match_expectation
            )
          @downstream_aliquots_updated =
            substituter.save ? true : log_error_and_return_false(substituter.errors.full_messages.join('; '))
        end

        def no_substitutions?
          substitutions.compact.all?(&:blank?)
        end

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
          duplicated_barcode_row = duplicate_barcodes
          return if duplicated_barcode_row.nil?

          errors.add(
            :base,
            "Barcode duplicated at row: #{duplicated_barcode_row.number}. The barcode must be unique for each tube."
          )
        end

        # Return the row of the first encountered barcode mismatch
        # rubocop:todo Metrics/MethodLength
        # rubocop:todo Metrics/AbcSize
        def duplicate_barcodes # rubocop:todo Metrics/CyclomaticComplexity
          return unless upload.respond_to?('rows')

          unique_bcs = []
          upload.rows.each do |row|
            next if row.columns.blank? || row.data.blank?

            col_num = row.columns.find_column_or_null(:name, 'sanger_tube_id').number
            next unless col_num.present? && col_num.positive?

            curr_bc = row.at(col_num)
            return row if unique_bcs.include?(curr_bc)

            unique_bcs << curr_bc
          end
          nil
        end
        # rubocop:enable Metrics/AbcSize
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
