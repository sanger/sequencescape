class AddCherrypickableTargetToPlatePurpose < ActiveRecord::Migration
  def self.up
    add_column :plate_purposes, :cherrypickable_target, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :plate_purposes, :cherrypickable_target
  end
end
