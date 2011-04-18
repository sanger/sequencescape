module ModelExtensions::Sample
  def self.included(base)
    base.class_eval do
      has_many :sample_tubes
      named_scope :include_studies, { :include => { :studies => :study_metadata } }
    end
  end

  def sample_reference_genome_name
    sample_reference_genome.try(:name)
  end

  def sample_reference_genome_name=(name)
    sample_metadata.reference_genome = ReferenceGenome.find_by_name(name)
  end
end
