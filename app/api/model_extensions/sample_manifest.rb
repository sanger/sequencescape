module ModelExtensions::SampleManifest
  def self.included(base)
    base.class_eval do
      named_scope :include_samples, {
        :include => {
          :samples => [
            :uuid_object,
            :primary_tube, {
              :sample_metadata => :reference_genome,
              :primary_well => [ :map, :plate ],
              :primary_study => { :study_metadata => :reference_genome }
            }
          ]
        }
      }
      delegate :io_samples, :to => :core_behaviour
    end
  end
end
