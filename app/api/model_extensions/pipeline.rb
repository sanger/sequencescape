#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
module ModelExtensions::Pipeline
  # If you need to do something to a batch based on updates it has received then this is the place to
  # do it.  The batch will be passed in and, really, you should call back into it to get the right
  # thing done.
  def manage_downstream_requests(batch)
    # By default nothing is done here!
  end
end
