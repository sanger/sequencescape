module Pipeline::InboxExtensions
  def inbox(show_held_requests = true, current_page = 1, search_action = nil)
    requests = proxy_association.scope
    pipeline = proxy_association.owner
    # Build a list of methods to invoke to build the correct request list
    actions = [:unbatched]
    actions << ((pipeline.group_by_parent? or show_held_requests) ? :full_inbox : :pipeline_pending)
    actions << [(pipeline.group_by_parent? ? :asset_on_labware : :with_present_asset)]

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
