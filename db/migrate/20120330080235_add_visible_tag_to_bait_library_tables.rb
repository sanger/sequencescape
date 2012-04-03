class AddVisibleTagToBaitLibraryTables < ActiveRecord::Migration
  def self.up
    add_column :bait_libraries, :visible, :boolean, :null => false, :default => true
    add_column :bait_library_types, :visible, :boolean, :null => false, :default => true
    add_column :bait_library_suppliers, :visible, :boolean, :null => false, :default => true
  end

  def self.down
    remove_column :bait_libraries, :visible
    remove_column :bait_library_types, :visible
    remove_column :bait_library_suppliers, :visible
  end
end
