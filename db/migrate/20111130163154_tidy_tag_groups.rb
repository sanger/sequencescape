#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class TidyTagGroups < ActiveRecord::Migration
  def self.up
    add_column :tag_groups, :visible, :boolean, :default => true
    TagGroup.update_all('visible = 0', [ 'name LIKE ?', '%do not use%' ])
  end

  def self.down
    remove_column :tag_groups, :visible
  end
end
