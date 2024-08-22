# frozen_string_literal: true
class AddTagSets < ActiveRecord::Migration[6.1]
  def change
    create_table :tag_sets do |t|
      t.string :name, null: false, unique: true
      t.references :tag_group, foreign_key: true, null: false, type: :integer
      t.references :tag2_group, foreign_key: { to_table: 'tag_groups' }, type: :integer

      t.timestamps
    end
  end
end
