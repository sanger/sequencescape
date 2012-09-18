class AddNoTargetAssetFlag < ActiveRecord::Migration
  def self.up
    add_column :request_types, :no_target_asset, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :request_types, :no_target_asset
  end
end
