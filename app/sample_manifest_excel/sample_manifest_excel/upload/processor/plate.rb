# frozen_string_literal: true

require_dependency 'sample_manifest_excel/upload/processor/base'
module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      ##
      # Processor to handle plate manifest uploads.
      class Plate < SampleManifestExcel::Upload::Processor::Base

        validate :check_for_retention_instruction_by_plate

        # For plate manifests the barcodes (sanger plate id column) should be the same for each well from the same
        # plate, and different for each plate.
        # Uniqueness of foreign barcodes in the database is checked in the specialised field sanger_plate_id.
        def check_for_barcodes_unique
          duplicated_barcode_row, err_msg = duplicate_barcodes
          return if duplicated_barcode_row.nil?

          errors.add(:base, "Barcode duplicated at row: #{duplicated_barcode_row.number}. #{err_msg}")
        end

        # Return the row of the first encountered barcode mismatch
        # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
        def duplicate_barcodes # rubocop:todo Metrics/CyclomaticComplexity
          return nil, nil unless upload.respond_to?(:rows)

          unique_bcs = {}
          unique_plates = {}
          upload.rows.each do |row|
            next if row.columns.blank? || row.data.blank?

            plate_barcode = row.value('sanger_plate_id')
            sample_id = row.value('sanger_sample_id')
            next if plate_barcode.nil? || sample_id.nil?

            plate_id_for_sample = find_plate_id_for_sample_id(sample_id)
            next if plate_id_for_sample.nil?

            # Check that a barcode is used for only one plate
            if unique_bcs.key?(plate_barcode)
              err_msg = 'Barcode is used in multiple plates.'
              return row, err_msg unless unique_bcs[plate_barcode] == plate_id_for_sample
            else
              unique_bcs[plate_barcode] = plate_id_for_sample
            end

            # Check that a plate has only one barcode
            if unique_plates.key?(plate_id_for_sample)
              err_msg = 'Plate has multiple barcodes.'
              return row, err_msg unless unique_plates[plate_id_for_sample] == plate_barcode
            else
              unique_plates[plate_id_for_sample] = plate_barcode
            end
          end
          [nil, nil]
        end

        # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

        def find_plate_id_for_sample_id(sample_id)
          sample_manifest_asset = SampleManifestAsset.find_by(sanger_sample_id: sample_id)
          sample_manifest_asset.labware&.id
        end

        # A subset of the plate manifests (stock plates not library plates) are required to have
        # a retention instruction column to describe how they should be disposed of. The column should
        # have the same value for all manifest rows for the same plate.
        def check_for_retention_instruction_by_plate
          retention_error_row, err_msg = non_matching_retention_instructions_for_plates
          return if retention_error_row.nil?

          errors.add(:base, "Retention instruction checks failed at row: #{retention_error_row.number}. #{err_msg}")
        end

        def non_matching_retention_instructions_for_plates
          return nil, nil unless upload.respond_to?(:rows)

          retention_instructions_for_plates = {}

          upload.rows.each do |row|
            # ignore empty rows and skip if the retention column is not present
            next if row.columns.blank? || row.data.blank? || row.columns.extract(['retention_instruction']).count.zero?

            plate_barcode = row.value('sanger_plate_id')
            sample_id = row.value('sanger_sample_id')

            # ignore rows where primary sample fields not filled in
            next if plate_barcode.nil? || sample_id.nil?

            sample_retention_instruction = row.value('retention_instruction')

            if sample_retention_instruction.nil? || sample_retention_instruction === 'Unknown'
              err_msg = "Value cannot be blank."
              return row, err_msg
            end

            # Check that a plate has only one retention instruction value
            if retention_instructions_for_plates.key?(plate_barcode)
              if retention_instructions_for_plates[plate_barcode] != sample_retention_instruction
                err_msg = "Plate (#{plate_barcode}) cannot have different retention instruction values."
                return row, err_msg
              end
            else
              retention_instructions_for_plates[plate_barcode] = sample_retention_instruction
            end
          end
          [nil, nil]
        end
      end
    end
  end
end
