class AddIndexesToSubmittedAssets < ActiveRecord::Migration
  def change
    add_index :submitted_assets, :asset_id
  end
end
