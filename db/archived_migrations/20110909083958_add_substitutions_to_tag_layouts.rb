#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddSubstitutionsToTagLayouts < ActiveRecord::Migration
  class TagLayout < ActiveRecord::Base
    self.table_name =('tag_layouts')
    serialize :subtitutions
  end

  def self.up
    add_column :tag_layouts, :substitutions, :string

    TagLayout.reset_column_information
    TagLayout.find_each do |layout|
      layout.update_attributes!(:subtitutions => {})
    end
  end

  def self.down
    remove_column :tag_layouts, :substitutions
  end
end
