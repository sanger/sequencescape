# No longer used directly the CherrypickForPulldownPipeline was previously an
# automated {CherrypickingPipeline} which attempted to automatically lay out
# target plates. However it proved tricky to model all the variations in the layout
# the users expected, and they stopped using the pipeline.
# However the {FlexibleCherrypickPipeline} is still active, and is sub-classed from this.
class CherrypickForPulldownPipeline < CherrypickingPipeline
  ALWAYS_SHOW_RELEASE_ACTIONS = true

  def post_finish_batch(batch, user)
    # Nothing, we don't want all the requests to be completed
  end

  def post_release_batch(batch, _user)
    batch.release_pending_requests
  end

  def update_detached_request(batch, request)
    # We do not need to do any of the default behaviour:
    # 1. The requests should just be detached, not blocked
    # 2. The assets are not removed because they are not considered unused
  end

  def all_requests_from_submissions_selected?(requests)
    request_types, submissions = request_types_and_submissions_for(requests)
    matching_requests = Request.where(request_type_id: request_types, submission_id: submissions).order(:id).pluck(:id)
    requests.map(&:id).sort == matching_requests
  end

  def request_types_and_submissions_for(requests)
    [requests.map(&:request_type_id).uniq, requests.map(&:submission_id).uniq]
  end
  private :request_types_and_submissions_for
end
