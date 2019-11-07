# Included in {SampleManifest}
# The intent of this file was to provide methods specific to the V1 API
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
