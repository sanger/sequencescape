# frozen_string_literal: true

class CreateTagSets < ActiveRecord::Migration[6.1]
  def change
    create_table :tag_sets do |t|
      t.string :name, null: false, unique: true
      t.references :tag_group, foreign_key: { to_table: :tag_groups }, null: true
      t.references :tag2_group, foreign_key: { to_table: :tag_groups }, null: true

      t.timestamps
    end

    add_index :tag_sets, :name, unique: true
  end
end
