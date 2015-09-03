#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class BroadcastEvent < ActiveRecord::Base

  extend BroadcastEvent::SubjectHelpers::SubjectableClassMethods

  belongs_to :seed, :polymorphic => true
  validates_presence_of :seed

  def initialize(*args)
    raise StandardError, 'BroadcastEvents can not be created directly' unless self.class < BroadcastEvent
    super
  end

  # Returns an array of all subjects
  def subjects
    self.class.subject_associations.map do |sa|
      sa.for(seed)
    end.flatten
  end

end
