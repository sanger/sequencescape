# Included in {AssetGroup} to provide scopes used by the V1 API
# @note This could easily be in-lined in asset group itself
module ModelExtensions::AssetGroup
  def self.included(base)
    base.class_eval do
      scope :include_study, -> { includes(:study) }
      scope :include_assets, -> { includes(:assets) }
    end
  end
end
