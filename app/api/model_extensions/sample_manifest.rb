module ModelExtensions::SampleManifest
  class SampleMapper
    def initialize(sample, container)
      @sample, @container = sample, container
    end

    def as_json(options = {})
      uuids_to_ids = options[:uuids_to_ids]

      {
        :container => @container,
        :sample    => ::Core::Io::Registry.instance.lookup_for_object(@sample).object_json(@sample, uuids_to_ids, options)
      }
    end
  end

  def self.included(base)
    base.class_eval do
      named_scope :include_samples, { :include => :samples }
      delegate :io_samples, :to => :core_behaviour
    end
  end
end
