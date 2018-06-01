
module ModelExtensions::SampleManifest
  def self.included(base)
    base.class_eval do
      scope :include_samples, -> {
        includes(
          samples: [
            :uuid_object, {
              sample_metadata: :reference_genome,
              primary_study: { study_metadata: :reference_genome }
            }
          ]
        )
      }
      delegate :io_samples, to: :core_behaviour
    end
  end
end
