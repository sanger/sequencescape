# Included in {Sample}
# The intent of this file was to provide methods specific to the V1 API
# @todo Rails relationships should probably be moved to Sample
module ModelExtensions::Sample
  def self.included(base)
    base.class_eval do
      scope :include_studies, -> { includes(studies: :study_metadata) }

      has_one :primary_study_samples, ->() { order(:study_id) }, class_name: 'StudySample'
      has_one :primary_study, through: :primary_study_samples, source: :study
      has_one :primary_study_metadata, through: :primary_study, source: :study_metadata
      has_one :study_reference_genome, through: :primary_study_metadata, source: :reference_genome
    end
  end

  def sample_reference_genome_name
    sample_reference_genome.try(:name)
  end

  def sample_reference_genome_name=(name)
    sample_metadata.reference_genome = ReferenceGenome.find_by(name: name)
  end
end
