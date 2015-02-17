#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
