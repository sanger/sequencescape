# frozen_string_literal: true
# Join table between an {Asset} and an {AssetGroup}
class AssetGroupAsset < ApplicationRecord
  belongs_to :asset, class_name: 'Receptacle', inverse_of: :asset_group_assets
  belongs_to :asset_group, inverse_of: :asset_group_assets
end
