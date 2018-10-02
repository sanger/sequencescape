module ModelExtensions::AssetGroup
  def self.included(base)
    base.class_eval do
      scope :include_study, -> { includes(:study) }
      scope :include_assets, -> { includes(:assets) }
    end
  end
end
