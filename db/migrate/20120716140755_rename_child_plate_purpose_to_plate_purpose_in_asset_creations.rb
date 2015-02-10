#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class RenameChildPlatePurposeToPlatePurposeInAssetCreations < ActiveRecord::Migration
  def self.up
    rename_column(:asset_creations, :child_plate_purpose_id, :child_purpose_id)
  end

  def self.down
    rename_column(:asset_creations, :child_purpose_id, :child_plate_purpose_id)
  end
end
