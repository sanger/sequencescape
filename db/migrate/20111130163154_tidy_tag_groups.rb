class TidyTagGroups < ActiveRecord::Migration
  def self.up
    # add_column :tag_groups, :visible, :boolean, :default => true
    hide_this = TagGroup.all(:conditions => { :name => 'Old 12 TagTubes - do not use'}).first
    unless hide_this.nil?
      hide_this.visible = false
      hide_this.save!
    end
  end

  def self.down
    remove_column :tag_groups, :visible
  end
end
