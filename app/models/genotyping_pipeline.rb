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
end
