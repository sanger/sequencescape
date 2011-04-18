class FacultySponsor < ActiveRecord::Base
  default_scope :order => :name
  
  validates_presence_of  :name
  validates_uniqueness_of :name, :message => "of faculty sponsor already present in database"
  
  acts_as_audited :on => [:destroy, :update]
  
  def count_studies
    Study.count(:joins => { :study_metadata => :faculty_sponsor }, :conditions => { :study_metadata => { :faculty_sponsor_id => self.id } })
  end
  
  def studies
    Study.find(:all, :joins => { :study_metadata => :faculty_sponsor }, :conditions => { :study_metadata => { :faculty_sponsor_id => self.id } })
  end
  
  def for_select_dropdown
    [self.name, self.id]
  end
  
  module Associations
    def self.included(base)
      base.validates_presence_of :faculty_sponsor_id
      base.belongs_to :faculty_sponsor
    end
  end
end
