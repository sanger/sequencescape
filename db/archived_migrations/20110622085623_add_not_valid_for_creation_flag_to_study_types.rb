#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddNotValidForCreationFlagToStudyTypes < ActiveRecord::Migration
  def self.up
    add_column :study_types, :valid_for_creation, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :study_types, :valid_for_creation
  end
end
