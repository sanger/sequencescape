#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class RenamePlateCreationsToAssetCreations < ActiveRecord::Migration
  def self.up
    rename_table(:plate_creations, :asset_creations)
  end

  def self.down
    rename_table(:asset_creations, :plate_creations)
  end
end
