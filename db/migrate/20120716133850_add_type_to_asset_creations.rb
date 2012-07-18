class AddTypeToAssetCreations < ActiveRecord::Migration
  class AssetCreation < ActiveRecord::Base
    set_table_name('asset_creations')
  end

  def self.up
    add_column(:asset_creations, :type, :string, :null => false)
    AssetCreation.update_all('type="PlateCreation"')
  end

  def self.down
    remove_column(:asset_creations, :type)
  end
end
