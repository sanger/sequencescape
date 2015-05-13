#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddMinimumVolumeToRobot < ActiveRecord::Migration
  def self.up
    alter_table :robots do |t|
      add_column :minimum_volume, :float
    end
  end

  def self.down
    alter_table :robots do |t|
      remove_column :minimum_volume
    end
  end
end
