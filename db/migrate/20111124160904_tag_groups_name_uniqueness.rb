#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class TagGroupsNameUniqueness < ActiveRecord::Migration
  
  def self.up
    execute <<-SQL
      ALTER TABLE tag_groups
      ADD CONSTRAINT tag_groups_unique_name UNIQUE (name)
    SQL
  end

  def self.down
    execute <<-SQL
      ALTER TABLE tag_groups
      DROP INDEX tag_groups_unique_name
    SQL
  end
end
