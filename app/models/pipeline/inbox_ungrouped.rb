#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
module Pipeline::InboxUngrouped
  def self.included(base)
    base.has_many :inbox, :class_name => 'Request', :extend => Pipeline::RequestsInStorage
  end

  # Never group by submission
  def group_by_submission?
    false
  end
end
