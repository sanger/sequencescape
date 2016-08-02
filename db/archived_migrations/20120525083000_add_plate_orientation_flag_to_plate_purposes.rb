#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddPlateOrientationFlagToPlatePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :plate_purposes, :cherrypick_direction, :string, :null => false, :default => 'column'
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :plate_purposes, :cherrypick_direction
    end
  end
end
