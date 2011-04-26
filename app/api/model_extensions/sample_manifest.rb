module ModelExtensions::SampleManifest
  def self.included(base)
    base.class_eval do
      named_scope :include_samples, { :include => :samples }
      delegate :io_samples, :to => :core_behaviour
    end
  end
end
