class TidyTagGroups < ActiveRecord::Migration
  def self.up
    add_column :tag_groups, :visible, :boolean, :default => true
    TagGroup.update_all('visible = 0', :conditions => ["name LIKE ?","'%do not use%'"])
  end

  def self.down
    remove_column :tag_groups, :visible
  end
end