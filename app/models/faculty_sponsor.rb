#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class FacultySponsor < ActiveRecord::Base
  extend Attributable::Association::Target

  default_scope :order => :name

  validates_presence_of  :name
  validates_uniqueness_of :name, :message => "of faculty sponsor already present in database"

  def count_studies
    Study.count(:joins => { :study_metadata => :faculty_sponsor }, :conditions => { :study_metadata => { :faculty_sponsor_id => self.id } })
  end

  def studies
    Study.find(:all, :joins => { :study_metadata => :faculty_sponsor }, :conditions => { :study_metadata => { :faculty_sponsor_id => self.id } })
  end

  module Associations
    def self.included(base)
      base.validates_presence_of :faculty_sponsor_id
      base.belongs_to :faculty_sponsor
    end
  end
end
