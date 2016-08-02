#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class CreateTagLayoutTemplates < ActiveRecord::Migration
  def self.up
    create_table :tag_layout_templates do |t|
      t.string     :layout_class_name
      t.references :tag_group
      t.string     :name
      t.timestamps
    end
  end

  def self.down
    drop_table :tag_layout_templates
  end
end
