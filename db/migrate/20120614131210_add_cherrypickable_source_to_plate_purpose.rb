class AddCherrypickableSourceToPlatePurpose < ActiveRecord::Migration
  def self.up
    add_column :plate_purposes, :cherrypickable_source, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :plate_purposes, :cherrypickable_source
  end
end
