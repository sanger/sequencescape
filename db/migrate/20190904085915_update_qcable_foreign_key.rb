# frozen_string_literal: true

# Remove foreign key pointing at old tables
class UpdateQcableForeignKey < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :qcables, column: :asset_id
    add_foreign_key :qcables, :labware, column: :asset_id
  end

  def down
    remove_foreign_key :qcables, column: :asset_id
    add_foreign_key :qcables, :assets_deprecated, column: :asset_id
  end
end
