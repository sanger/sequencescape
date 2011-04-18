class PulldownMultiplexLibraryPreparationPipeline < Pipeline
  INBOX_PARTIAL='group_by_parent'
  
  def inbox_partial
    INBOX_PARTIAL
  end
end
