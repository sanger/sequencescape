module ModelExtensions::AssetGroup
  def self.included(base)
    base.class_eval do
      named_scope :include_study, { :include => :study }
      named_scope :include_assets, { :include => :assets }
    end
  end
end
