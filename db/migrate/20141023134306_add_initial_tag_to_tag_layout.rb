#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddInitialTagToTagLayout < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      add_column :tag_layouts, :initial_tag, :integer, :null=>false, :default=>0
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_column :tag_layouts, :initial_tag
    end
  end
end
