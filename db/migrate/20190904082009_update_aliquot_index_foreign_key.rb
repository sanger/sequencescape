# frozen_string_literal: true

# Remove foreign key pointing at old tables
class UpdateAliquotIndexForeignKey < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :aliquot_indices, column: :lane_id
    add_foreign_key :aliquot_indices, :receptacles, column: :lane_id
  end

  def down
    remove_foreign_key :aliquot_indices, column: :lane_id
    add_foreign_key :aliquot_indices, :assets_deprecated, column: :lane_id
  end
end
