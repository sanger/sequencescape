# frozen_string_literal: true
module RetentionInstructionHelper
  # Return the retention instruction options for select
  def retention_instruction_option_for_select
    Labware.retention_instructions.keys.map { |option| [I18n.t("retention_instructions.#{option}"), option] }
  end

  # Find the retention instruction value based on the key
  def find_retention_instruction_from_key(key)
    value = I18n.t("retention_instructions.#{key}")
    return nil if value.include?('Translation missing:')
    value
  end

  # Retrieve the I18n key for a given value in the retention_instructions hash
  def find_retention_instruction_key_for_value(value)
    key = I18n.t(:retention_instructions).key(value)
    return key if key
    nil
  end

  # A subset of the plate manifests (stock plates not library plates) are required to have
  # a retention instruction column to describe how they should be disposed of. The column should
  # have the same value for all manifest rows for the same plate.
  def check_for_retention_instruction_by_plate
    retention_error_row, err_msg = non_matching_retention_instructions_for_plates
    return if retention_error_row.nil?

    errors.add(:base, "Retention instruction checks failed at row: #{retention_error_row.number}. #{err_msg}")
  end

  # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
  def non_matching_retention_instructions_for_plates
    return nil, nil unless upload.respond_to?(:rows)

    # Initialize empty retention_instructions hash to store retention instructions
    upload
      .rows
      .each_with_object({}) do |row, retention_instructions|
      # ignore empty rows and skip if the retention column is not present
      next if row.columns.blank? || row.data.blank? || row.columns.extract(['retention_instruction']).count.zero?

      plate_barcode = row.value('sanger_plate_id')
      sample_id = row.value('sanger_sample_id')

      # ignore rows where primary sample fields have not been filled in
      next unless plate_barcode.present? && sample_id.present?

      # check the row retention instruction is valid
      err_msg = check_row_retention_value(row, plate_barcode, retention_instructions)
      return row, err_msg if err_msg.present?
    end
    [nil, nil]
  end

  # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
  def check_row_retention_value(row, plate_barcode, retention_instructions)
    # if present the column is mandatory
    row_retention_value = row.value('retention_instruction')
    return 'Value cannot be blank.' if row_retention_value.nil?

    # Check that a plate has only one retention instruction value
    retention_instruction_key = find_retention_instruction_key_for_value(row_retention_value)
    return "Invalid retention instruction #{retention_instruction_key}" if retention_instruction_key.blank?
    if retention_instructions.key?(plate_barcode)
      if retention_instructions[plate_barcode] != retention_instruction_key
        return "Plate (#{plate_barcode}) cannot have different retention instruction values."
      end
    else
      # first time we are seeing this plate, add it to plate retentions hash
      retention_instructions[plate_barcode] = retention_instruction_key
    end
    nil
  end
end
