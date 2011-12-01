class TidyTagGroups < ActiveRecord::Migration
  def self.up
    # add_column :tag_groups, :visible, :boolean, :default => true
    TagGroup.find_each(:conditions => "name LIKE '%do not use%'") do |hide_this|
      hide_this.visible = false
      hide_this.save!
    end
  end

  def self.down
    remove_column :tag_groups, :visible
  end
end
