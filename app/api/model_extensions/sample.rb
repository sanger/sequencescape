module ModelExtensions::Sample
  def self.included(base)
    base.class_eval do
      has_many :sample_tubes
      named_scope :include_studies, { :include => { :studies => :study_metadata } }

      has_one :primary_well, :class_name => 'Well', :order => 'created_at'
      has_one :primary_tube, :class_name => 'SampleTube', :order => 'created_at'
    end
  end

  def sample_reference_genome_name
    sample_reference_genome.try(:name)
  end

  def sample_reference_genome_name=(name)
    sample_metadata.reference_genome = ReferenceGenome.find_by_name(name)
  end
end
