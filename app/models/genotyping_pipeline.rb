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
