class PulldownMultiplexLibraryPreparationPipeline < Pipeline
  INBOX_PARTIAL               = 'group_by_parent'
  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def inbox_partial
    INBOX_PARTIAL
  end
end
