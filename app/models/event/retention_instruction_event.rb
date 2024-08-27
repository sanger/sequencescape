# frozen_string_literal: true

class Event::RetentionInstructionEvent < Event
  def self.create_for_labware!(asset, user)
    return if asset.retention_instruction.blank?
    create!(
      eventful: asset,
      message: "Set retention instruction to #{asset.retention_instruction}",
      content: 'Content',
      family: 'set_retention_instruction',
      created_by: user ? user.login : nil
    )
  end
end
