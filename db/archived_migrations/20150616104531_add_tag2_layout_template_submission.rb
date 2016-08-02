#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddTag2LayoutTemplateSubmission < ActiveRecord::Migration

  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    create_table :tag2_layout_template_submissions do |t|
      t.integer "submission_id",           :null => false
      t.integer "tag2_layout_template_id", :null => false
      t.timestamps
    end

    add_index "tag2_layout_template_submissions", ["submission_id", "tag2_layout_template_id"], :name => "tag2_layouts_used_once_per_submission", :unique => true

    add_constraint('tag2_layout_template_submissions','submissions')
    add_constraint('tag2_layout_template_submissions','tag2_layout_templates')
  end

  def self.down
    drop_constraint('tag2_layout_template_submissions','submissions')
    drop_constraint('tag2_layout_template_submissions','tag2_layout_templates')
    drop_table :tag2_layout_template_submission
  end
end
