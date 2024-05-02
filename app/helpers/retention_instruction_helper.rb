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

  # This function is used to find the retention instruction to display for a given asset
  # NB: The elsif statement in the function will not be necessary after the script in #4095 is run,.
  # After the script in #4095 is run, the elsif branch can be removed.
  def find_retention_instruction_to_display(asset)
    metadata = asset.metadata

    if asset.retention_instruction.present?
      return asset.retention_instruction
    elsif asset.custom_metadatum_collection.present? && metadata.key?('retention_instruction')
      return find_retention_instruction_key_for_value(metadata['retention_instruction'])
    end
    nil
  end

end
