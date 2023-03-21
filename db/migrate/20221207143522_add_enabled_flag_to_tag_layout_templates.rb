# frozen_string_literal: true

# Add an enabled column to tag_layout_templates with a default value of true
class AddEnabledFlagToTagLayoutTemplates < ActiveRecord::Migration[6.0]
  def change
    add_column :tag_layout_templates, :enabled, :boolean, default: true, null: false
  end
end
