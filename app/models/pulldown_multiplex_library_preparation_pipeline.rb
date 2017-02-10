# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class PulldownMultiplexLibraryPreparationPipeline < Pipeline
  INBOX_PARTIAL               = 'group_by_parent'
  ALWAYS_SHOW_RELEASE_ACTIONS = true

  self.batch_worksheet = 'pulldown_worksheet'

  def inbox_partial
    INBOX_PARTIAL
  end
end
