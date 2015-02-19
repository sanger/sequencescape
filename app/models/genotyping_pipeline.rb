#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2013 Genome Research Ltd.
class GenotypingPipeline < Pipeline
  include Pipeline::InboxGroupedBySubmission
  INBOX_PARTIAL               = 'group_by_parent'
  ALWAYS_SHOW_RELEASE_ACTIONS = true


  def inbox_partial
    INBOX_PARTIAL
  end

  def genotyping?
    true
  end

  # Pipelines in Genotyping do not require their batches to record the position of the requests.
  def requires_position?
    false
  end

  def request_actions
    [:fail,:remove]
  end
end
