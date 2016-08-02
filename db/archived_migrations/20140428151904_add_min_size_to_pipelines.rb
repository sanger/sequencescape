#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddMinSizeToPipelines < ActiveRecord::Migration
  def self.up
    add_column :pipelines, :min_size, :integer, :null => true
  end

  def self.down
    remove_column :pipelines, :min_size
  end
end
