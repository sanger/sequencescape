# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

class GenotypingPipeline < Pipeline
  include Pipeline::InboxGroupedBySubmission

  self.inbox_partial = 'group_by_parent'
  self.requires_position = false
  self.genotyping = true

  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def request_actions
    [:fail, :remove]
  end
end
