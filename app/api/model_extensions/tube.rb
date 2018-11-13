module ModelExtensions::Tube
  def self.included(base)
    base.class_eval do
      scope :include_purpose, -> { includes(:purpose) }
    end
  end
end
