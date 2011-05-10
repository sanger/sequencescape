module ModelExtensions::SampleManifest
  def self.included(base)
    base.class_eval do
      named_scope :include_samples, { :include => { :samples => [ :uuid_object, :sample_metadata, { :primary_well => [ :map, :plate ] }, :primary_tube ] } }
      delegate :io_samples, :to => :core_behaviour
    end
  end
end
