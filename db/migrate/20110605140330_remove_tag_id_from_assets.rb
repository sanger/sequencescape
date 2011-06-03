class RemoveTagIdFromAssets < ActiveRecord::Migration
  def self.up
    remove_column :assets, :tag_id
  end

  def self.down
    add_column :assets, :tag_id
  end
end
