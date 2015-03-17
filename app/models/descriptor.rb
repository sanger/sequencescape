#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
class Descriptor < ActiveRecord::Base
  belongs_to :task
  serialize :selection

  def is_required?
    self.required
  end

  def matches?(search)
    search.descriptors.each do |descriptor|
      if descriptor.name == self.name && descriptor.value == self.value
        return true
      end
    end
    false
  end

end
