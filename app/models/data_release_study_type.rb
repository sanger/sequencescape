class DataReleaseStudyType < ActiveRecord::Base 
  has_many :study
  
  validates_presence_of  :name
  validates_uniqueness_of :name, :message => "of data release study type already present in database"

  UNSPECIFIED = 'not specified'
  TYPES = ['transcriptomics','other sequencing-based-assay','genotyping or cytogenetics' ]
  
  def for_select_dropdown
    [self.name, self.id]
  end  
 
  def is_not_specified?
    self.name == UNSPECIFIED
  end

  def include_type?
    TYPES.include?(self.name)
  end
  
  module Associations
    def self.included(base)
      base.validates_presence_of :data_release_study_type_id
      base.belongs_to :data_release_study_type
    end
  end
end
