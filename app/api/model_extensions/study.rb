
module ModelExtensions::Study
  def self.included(base)
    base.class_eval do
      scope :include_samples, -> { includes(:samples) }
      scope :include_projects, -> { includes(:projects) }
    end
  end
end
