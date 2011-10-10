class DataReleaseStudyType < ActiveRecord::Base 
  extend Attributable::Association::Target

  has_many :study
  
  validates_presence_of  :name
  validates_uniqueness_of :name, :message => "of data release study type already present in database"

  TYPES = ['transcriptomics','other sequencing-based-assay','genotyping or cytogenetics' ]
 
  def is_not_specified?
    false
  end

  def include_type?
    TYPES.include?(self.name)
  end

  def self.default
    first(:conditions => { :is_default => true })
  end

  module Associations
    def self.included(base)
      base.validates_presence_of :data_release_study_type_id
      base.belongs_to :data_release_study_type
    end
  end
end
