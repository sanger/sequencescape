# Rails migration
class AddTag2GroupColumnToTagLayouts < ActiveRecord::Migration[4.2]
  def change
    add_reference :tag_layouts, :tag2_group
    add_foreign_key :tag_layouts, :tag_groups, column: :tag2_group_id
  end
end
