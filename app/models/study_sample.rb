#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class StudySample < ActiveRecord::Base
  include Api::StudySampleIO::Extensions
  cattr_reader :per_page
  @@per_page = 500
  include Uuid::Uuidable

  belongs_to :study
  belongs_to :sample


  validates_uniqueness_of :sample_id, :scope => [:study_id], :message => "cannot be added to the same study more than once"
end
