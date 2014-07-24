class CherrypickPipeline < CherrypickingPipeline
  include Pipeline::InboxGroupedBySubmission

  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def post_finish_batch(batch, user)
    # Nothing, we don't want all the requests to be completed
  end

  def post_release_batch(batch, user)
    batch.release_pending_requests()
  end

  def update_detached_request(batch, request)
    # We do not need to do any of the default behaviour:
    # 1. The requests should just be detached, not blocked
    # 2. The assets are not removed because they are not considered unused
  end
end
