class GenotypingPipeline < Pipeline
  include Pipeline::InboxGroupedBySubmission
  include Pipeline::GroupByParent

  self.requires_position = false
  self.genotyping = true

  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def request_actions
    %i[fail remove]
  end

  private

  def grouping_parser
    Pipeline::GrouperByParentAndSubmission.new(self)
  end
end
