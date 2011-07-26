class CreateTagLayouts < ActiveRecord::Migration
  def self.up
    create_table :tag_layouts do |t|
      t.string     :sti_type
      t.references :tag_group
      t.references :plate
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :tag_layouts
  end
end
