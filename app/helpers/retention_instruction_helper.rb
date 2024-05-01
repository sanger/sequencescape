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

end
