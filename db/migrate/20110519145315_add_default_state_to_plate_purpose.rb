#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddDefaultStateToPlatePurpose < ActiveRecord::Migration
  def self.up
    add_column :plate_purposes, :default_state, :string, :default => 'pending'
    PlatePurpose.reset_column_information
  end

  def self.down
    remove_column :plate_purposes, :default_state
  end
end
