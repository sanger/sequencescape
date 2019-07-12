# Join table between an {Asset} and an {AssetGroup}
class AssetGroupAsset < ApplicationRecord
  # This block is disabled when we have the labware table present as part of the AssetRefactor
  # Ie. This is what will happens now
  AssetRefactor.when_not_refactored do
    # Fixes rails scoping bug
    default_scope ->() { includes(:asset, :asset_group) }
  end
  belongs_to :asset, class_name: 'Receptacle', inverse_of: :asset_group_assets
  belongs_to :asset_group, inverse_of: :asset_group_assets
end
