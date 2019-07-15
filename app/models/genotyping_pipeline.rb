class GenotypingPipeline < Pipeline
  include Pipeline::InboxGroupedBySubmission
  include Pipeline::GroupByParent

  self.requires_position = false
  self.genotyping = true

  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def request_actions
    [:fail, :remove]
  end
end
