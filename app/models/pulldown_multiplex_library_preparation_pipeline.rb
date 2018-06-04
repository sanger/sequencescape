
class PulldownMultiplexLibraryPreparationPipeline < Pipeline
  self.inbox_partial = 'group_by_parent'
  ALWAYS_SHOW_RELEASE_ACTIONS = true

  self.batch_worksheet = 'legacy_worksheet'
end
