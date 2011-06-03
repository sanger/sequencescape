module ModelExtensions::Sample
  def self.included(base)
    base.class_eval do
      named_scope :include_studies, { :include => { :studies => :study_metadata } }

      has_one :primary_study, :through => :study_samples, :source => :study, :order => 'study_id'
    end
  end

  def sample_reference_genome_name
    sample_reference_genome.try(:name)
  end

  def sample_reference_genome_name=(name)
    sample_metadata.reference_genome = ReferenceGenome.find_by_name(name)
  end
end
