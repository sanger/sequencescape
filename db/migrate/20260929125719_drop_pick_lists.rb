# frozen_string_literal: true
class DropPickLists < ActiveRecord::Migration[8.1]
  def up
    drop_table :pick_lists
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'The pick_lists table cannot be reconstructed.'
  end
end
