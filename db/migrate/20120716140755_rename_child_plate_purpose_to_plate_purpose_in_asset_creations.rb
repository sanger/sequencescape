class RenameChildPlatePurposeToPlatePurposeInAssetCreations < ActiveRecord::Migration
  def self.up
    rename_column(:asset_creations, :child_plate_purpose_id, :child_purpose_id)
  end

  def self.down
    rename_column(:asset_creations, :child_purpose_id, :child_plate_purpose_id)
  end
end
