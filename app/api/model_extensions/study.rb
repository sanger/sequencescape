module ModelExtensions::Study
  def self.included(base)
    base.class_eval do
      named_scope :include_samples, :include => :samples
      named_scope :include_projects, :include => :projects
    end
  end
end
