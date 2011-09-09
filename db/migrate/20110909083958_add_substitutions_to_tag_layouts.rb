class AddSubstitutionsToTagLayouts < ActiveRecord::Migration
  class TagLayout < ActiveRecord::Base
    set_table_name('tag_layouts')
    serialize :subtitutions
  end

  def self.up
    add_column :tag_layouts, :substitutions, :string

    TagLayout.reset_column_information
    TagLayout.find_each do |layout|
      layout.update_attributes!(:subtitutions => {})
    end
  end

  def self.down
    remove_column :tag_layouts, :substitutions
  end
end
