# frozen_string_literal: true

require_dependency 'sample_manifest_excel/upload/processor/base'
module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      ##
      # Processor to handle plate manifest uploads.
      class Plate < SampleManifestExcel::Upload::Processor::Base
        include RetentionInstructionHelper

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
      end
    end
  end
end
