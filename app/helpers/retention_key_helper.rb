module RetentionKeyHelper
  # Return the retention instruction options for select
  def retention_instruction_option_for_select
    Labware.retention_instruction.keys.map do |option|
      [I18n.t("retention_instructions.#{option}"), option]
    end
  end

  # Retrieve the I18n key for a given value in the retention_instructions hash
  def find_retention_instruction_key_for_value(value)
    key = I18n.t(:retention_instructions).key(value)
    return key if key
    nil
  end
end
