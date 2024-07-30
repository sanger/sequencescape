# frozen_string_literal: true

class CreateTagSets < ActiveRecord::Migration[6.1]
  def change
    create_table :tag_sets do |t|
      t.string :name, null: false, unique: true
      t.integer :tag_group_id, foreign_key: { to_table: :tag_groups }, null: true
      t.integer :tag2_group_id, foreign_key: { to_table: :tag_groups }, null: true

      t.timestamps
    end

    add_index :tag_sets, :name, unique: true
  end
end
