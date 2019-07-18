# Rails migration
class AddTag2GroupToTagLayoutTemplates < ActiveRecord::Migration[4.2]
  def change
    add_reference :tag_layout_templates, :tag2_group
    add_foreign_key :tag_layout_templates, :tag_groups, column: :tag2_group_id
  end
end
