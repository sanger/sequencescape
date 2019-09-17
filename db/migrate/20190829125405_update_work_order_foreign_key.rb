# frozen_string_literal: true

# Ensure barcodes points at labware, not assets
class UpdateWorkOrderForeignKey < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :work_completions, column: :target_id
    add_foreign_key :work_completions, :labware, column: :target_id
  end
end
