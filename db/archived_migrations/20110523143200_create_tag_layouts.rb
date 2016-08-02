#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class CreateTagLayouts < ActiveRecord::Migration
  def self.up
    create_table :tag_layouts do |t|
      t.string     :sti_type
      t.references :tag_group
      t.references :plate
      t.references :user
      t.timestamps
    end
  end

  def self.down
    drop_table :tag_layouts
  end
end
