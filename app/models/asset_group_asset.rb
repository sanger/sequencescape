class AssetGroupAsset < ActiveRecord::Base
  belongs_to :asset
  belongs_to :asset_group
  acts_as_audited :on => [:destroy, :update]

end
