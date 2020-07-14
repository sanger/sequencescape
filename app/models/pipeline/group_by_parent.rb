# frozen_string_literal: true

# Pipelines which group by parent typically have plate inputs, and ensure that they are all processed together
module Pipeline::GroupByParent
  extend ActiveSupport::Concern

  included do
    self.inbox_partial = 'group_by_parent'
    self.group_by_parent = true
  end

  def input_labware(requests)
    labware_report(:requests_as_source, requests, group_by: groups)
  end

  def output_labware(requests)
    labware_report(:requests_as_target, requests)
  end

  def requests_in_inbox(_show_held_requests = true)
    # @note This has been added while I refactor the pipeline inboxes. Ideally we'll
    #       eventually unify their interfaces
    raise StandardError, 'Use the Presenters::GroupedPipelineInboxPresenter'
  end

  def extract_requests_from_input_params(params)
    selected_groups = params.fetch('request_group')
    grouping_parser.all(selected_keys_from(selected_groups))
  end

  private

  def labware_report(request_association, requests, group_by: 'labware.id')
    Labware.joins(request_association)
           .where('requests.id' => requests)
           .preload(:barcodes, :purpose)
           .group(group_by)
           .select('labware.*', 'COUNT(DISTINCT requests.id) AS request_count')
  end

  # Note can be overidden if also grouping by submission
  def grouping_parser
    Pipeline::GrouperByParent.new(self)
  end

  def groups
    return ['labware.id', 'requests.submission_id'] if group_by_submission?

    'labware.id'
  end
end
