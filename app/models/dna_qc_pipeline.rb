class DnaQcPipeline < GenotypingPipeline
  include Pipeline::InboxGroupedBySubmission

  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def post_finish_batch(batch, user)
    # Nothing, we don't want all the requests to be completed
  end

  def post_release_batch(batch, user)
    batch.release_pending_requests()
  end
end
