#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddIndexTagLayoutTemplateTable < ActiveRecord::Migration
  def self.up
    create_table :tag2_layout_templates do |t|
      t.string  :name, :null => false
      t.integer :tag_id, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :tag2_layout_templates
  end
end
