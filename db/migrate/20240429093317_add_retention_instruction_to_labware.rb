# frozen_string_literal: true
class AddRetentionInstructionToLabware < ActiveRecord::Migration[6.1]
  def up
    add_column :labware, :retention_instruction, :integer
  end

  def down
    remove_column :labware, :retention_instruction
  end
end
