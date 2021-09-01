class GenotypingPipeline < Pipeline # rubocop:todo Style/Documentation
  include Pipeline::InboxGroupedBySubmission
  include Pipeline::GroupByParent

  self.requires_position = false
  self.genotyping = true

  def request_actions
    %i[fail remove]
  end

  private

  def grouping_parser
    Pipeline::GrouperByParentAndSubmission.new(self)
  end
end
