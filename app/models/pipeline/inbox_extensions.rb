# frozen_string_literal: true
module Pipeline::InboxExtensions # rubocop:todo Style/Documentation
  # Used by the Pipeline class to retrieve the list of requests that are coming into the pipeline.
  def inputs(show_held_requests = false)
    ready_in_storage.send(show_held_requests ? :full_inbox : :pipeline_pending)
  end
end
