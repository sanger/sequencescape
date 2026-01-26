# frozen_string_literal: true

module SampleManifestExcel
  module Upload
    module Processor
      # TODO: had to explicitly specify the namespace for Base here otherwise it picks up Upload::Base
      # Processor to handle 1dtube uploads
      class OneDTube < SampleManifestExcel::Upload::Processor::Base
        # validate :check_for_retention_instruction

        # # All extraction tubes on the same manifest must have the same retention instructions.
        # def check_for_retention_instruction
        #   retention_error_row, err_msg = non_matching_retention_instructions
        #   return if retention_error_row.nil?

        #   errors.add(:base, "Retention instruction checks failed at row: #{retention_error_row.number}. #{err_msg}")
        # end

        # # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
        # def non_matching_retention_instructions
        #   return nil, nil unless upload.respond_to?(:rows)

        #   upload
        #     .rows
        #     .each_with_object({}) do |row, tube_retentions|
        #       # ignore empty rows and skip if the retention column is not present
        #       if row.columns.blank? || row.data.blank? || row.columns.extract(['retention_instruction']).count.zero?
        #         next
        #       end

        #       tube_barcode = row.value('sanger_tube_id')
        #       sample_id = row.value('sanger_sample_id')

        #       # ignore rows where primary sample fields have not been filled in
        #       next unless tube_barcode.present? && sample_id.present?

        #       # check the row retention instruction is valid
        #       err_msg = check_row_retention_value(row, tube_barcode, tube_retentions)
        #       return row, err_msg if err_msg.present?
        #     end
        #   [nil, nil]
        # end

        # # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
        # def check_row_retention_value(row, tube_barcode, tube_retentions)
        #   # if present the column is mandatory
        #   row_retention_value = row.value('retention_instruction')
        #   return 'Value cannot be blank.' if row_retention_value.nil?

        #   # Check that the manifest has only one retention instruction value
        #   if tube_retentions.key?('first')
        #     if tube_retentions['first'] != row_retention_value
        #       return "Tube (#{tube_barcode}) cannot have different retention instruction value."
        #     end
        #   else
        #     # first time we are seeing a tube, add its retention value to hash
        #     tube_retentions['first'] = row_retention_value
        #   end
        #   nil
        # end
      end
    end
  end
end
