# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

module Pipeline::InboxExtensions
  def inbox(show_held_requests = true, current_page = 1, search_action = nil)
    requests = proxy_association.scope
    pipeline = proxy_association.owner
    # Build a list of methods to invoke to build the correct request list
    actions = [:unbatched]
    actions.concat(pipeline.custom_inbox_actions)
    actions << ((pipeline.group_by_parent? or show_held_requests) ? :full_inbox : :pipeline_pending)
    actions << [(pipeline.group_by_parent? ? :holder_located : :with_present_asset)]

    if search_action != :count
      actions << :include_request_metadata if pipeline.request_information_types.exists?
      actions << (pipeline.group_by_submission? ? :ordered_for_submission_grouped_inbox : :ordered_for_ungrouped_inbox)
      actions << pipeline.inbox_eager_loading
    end

    if search_action.present?
      actions << [search_action]
    elsif pipeline.paginate?
      actions << [:paginate, { per_page: 50, page: current_page }]
    end

    actions.inject(requests) { |context, action| context.send(*Array(action)) }
  end

  # Used by the Pipeline class to retrieve the list of requests that are coming into the pipeline.
  def inputs(show_held_requests = false)
    ready_in_storage.send(show_held_requests ? :full_inbox : :pipeline_pending)
  end
end
