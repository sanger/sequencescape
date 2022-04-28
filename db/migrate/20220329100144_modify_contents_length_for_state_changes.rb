# frozen_string_literal: true

# Increasing the size of the contents column in the state_changes table to
# cope with 384-well plates.
# NB. Will likely throw error on down if data greater than old length has been added to column.
class ModifyContentsLengthForStateChanges < ActiveRecord::Migration[6.0]
  def up
    change_column :state_changes, :contents, :string, limit: 4096
  end

  def down
    change_column :state_changes, :contents, :string, limit: 1024
  end
end
