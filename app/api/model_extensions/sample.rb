#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
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
