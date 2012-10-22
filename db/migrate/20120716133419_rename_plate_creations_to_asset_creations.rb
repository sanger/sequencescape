class RenamePlateCreationsToAssetCreations < ActiveRecord::Migration
  def self.up
    rename_table(:plate_creations, :asset_creations)
  end

  def self.down
    rename_table(:asset_creations, :plate_creations)
  end
end
