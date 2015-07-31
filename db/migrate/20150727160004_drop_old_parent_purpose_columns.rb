#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class DropOldParentPurposeColumns < ActiveRecord::Migration
  def self.up
    remove_column :plate_creator_purposes, :parent_purpose_id
  end

  def self.down
    add_column :plate_creator_purposes, :parent_purpose_id, :integer
  end
end
