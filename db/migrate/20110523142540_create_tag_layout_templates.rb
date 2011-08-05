class CreateTagLayoutTemplates < ActiveRecord::Migration
  def self.up
    create_table :tag_layout_templates do |t|
      t.string     :layout_class_name
      t.references :tag_group
      t.string     :name
      t.timestamps
    end
  end

  def self.down
    drop_table :tag_layout_templates
  end
end
