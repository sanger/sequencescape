# frozen_string_literal: true

# In order to simplify things, we'll be removing the unused or redundant columns
class DropUnusedColumns < ActiveRecord::Migration[5.2]
  def up
    change_column :lab_events, :description, :string
    remove_column :lab_events, :descriptor_fields, type: :text, limit: 16_777_215
    remove_column :lab_events, :filename, type: :string
    remove_column :lab_events, :data, type: :binary
  end

  def down
    change_column :lab_events, :description, :text, limit: 16_777_215
    add_column :lab_events, :descriptor_fields, :text, limit: 16_777_215
    add_column :lab_events, :filename, :string
    add_column :lab_events, :data, :binary
  end
end
