# frozen_string_literal: true
class Event::RetentionInstructionEvent < Event
  def self.created_retention_instruction!(retention_instruction, user)
    create!(
      eventful: retention_instruction,
      message: 'Retention instruction created',
      content: Date.today.to_s,
      family: 'created_retention_instruction',
      created_by: user ? user.login : nil
    )
  end

  def self.updated_retention_instruction!(retention_instruction, user)
    create!(
      eventful: retention_instruction,
      message: 'Updated by Sample Manifest',
      content: Date.today.to_s,
      family: 'updated_retention_instruction',
      created_by: user&.login
    )
  end
end
