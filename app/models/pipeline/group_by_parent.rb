# frozen_string_literal: true

# Pipelines which group by parent typically have plate inputs, and ensure that they are all processed together
module Pipeline::GroupByParent
  extend ActiveSupport::Concern

  included do
    self.inbox_partial = 'group_by_parent'
    self.group_by_parent = true
  end

  # Overridden in group-by parent pipelines to display input plates
  def input_labware(requests)
    requests.asset_on_labware.select('requests.*').group_by(&grouping_function)
  end

  # Overridden in group-by parent pipelines to display output
  def output_labware(requests)
    requests.target_asset_on_labware.group_by { |request| [request.labware_id] }
  end

  def requests_in_inbox(_show_held_requests = true)
    # @note This has been added while I refactor the pipeline inboxes. Ideally we'll
    #       eventually unify their interfaces
    raise StandardError, 'Use the Presenters::GroupedPipelineInboxPresenter'
  end

  private

  def grouping_function
    lambda do |request|
      [].tap do |group_key|
        group_key << request.labware_id
        group_key << request.submission_id if group_by_submission?
      end
    end
  end
end
