#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class LinkWellsToStockWells < ActiveRecord::Migration
  def self.up
    create_table(:well_links) do |t|
      t.references(:target_well, :null => false)
      t.references(:source_well, :null => false)
      t.string(:type, :null => false)
    end
    add_index([:target_well, :source_well, :type], :name => :unique_well_link_types_idx, :uniq => true)
  end

  def self.down
    drop_table(:well_links)
  end
end
