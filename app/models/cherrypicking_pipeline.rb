# frozen_string_literal: true
# Superclass for all Cherrypicking pipelines. Not used directly
class CherrypickingPipeline < Pipeline
  include Pipeline::InboxGroupedBySubmission
  include Pipeline::GroupByParent

  PICKED_STATES = %w[completed released].freeze

  self.batch_worksheet = 'cherrypick_worksheet'
  self.inbox_eager_loading = :loaded_for_grouped_inbox_display
  self.asset_type = 'Well'
  self.pick_data = true

  def robot_verified!(batch)
    batch.requests.each { |request| request.reduce_source_volume if request.respond_to?(:reduce_source_volume) }
  end

  def pick_information?(batch)
    PICKED_STATES.include?(batch.state)
  end

  def request_actions
    %i[fail remove]
  end

  private

  def grouping_parser
    Pipeline::GrouperByParentAndSubmission.new(self)
  end
end
