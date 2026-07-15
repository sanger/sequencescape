# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      # Processor to handle 1dtube uploads
      class OneDTube < SampleManifestExcel::Upload::Processor::Base
        validate :check_for_retention_instruction

        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
        def check_for_retention_instruction
          upload.rows.each do |row|
            # ignore empty rows and skip if the retention column is not present
            next if row.columns.blank? || row.data.blank? || row.columns.extract(['retention_instruction']).count.zero?

            tube_barcode = row.value('sanger_tube_id')
            sample_id = row.value('sanger_sample_id')

            # ignore rows where primary sample fields have not been filled in
            next unless tube_barcode.present? && sample_id.present?

            # check the row retention instruction is valid
            err_msg = check_row_retention_value(row)
            next unless err_msg

            errors.add(
              :base,
              "Retention instruction checks failed at row: #{row.number}. #{err_msg}"
            )
            break
          end
        end

        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
        def check_row_retention_value(row)
          # if present the column is mandatory
          'Value cannot be blank.' if row.value('retention_instruction').nil?
        end
      end
    end
  end
end
