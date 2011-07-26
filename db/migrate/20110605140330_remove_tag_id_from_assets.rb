class RemoveTagIdFromAssets < ActiveRecord::Migration
  def self.up
    rename_column :assets, :tag_id, :legacy_tag_id
  end

  def self.down
    rename_column :assets, :legacy_tag_id, :tag_id
  end
end
