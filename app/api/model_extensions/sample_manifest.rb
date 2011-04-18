module ModelExtensions::SampleManifest
  def self.included(base)
    base.class_eval do
      named_scope :include_samples, { :include => :samples }
    end
  end

  def io_samples
    core_behaviour.io_samples.map(&:as_json)
  end
end
