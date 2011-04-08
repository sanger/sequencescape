class CherrypickForPulldownPipeline < CherrypickingPipeline
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
  
  
  def all_requests_from_submissions_selected?(request_ids)
    requests = Request.find(request_ids, :include => [:submission])
    expected_requests = all_request_from_submissions_filtered_by_request_type(submissions_from_requests(requests),requests.first.request_type)
    return true if requests.size == expected_requests.size
    
    false
  end
  
  private
  def all_request_from_submissions_filtered_by_request_type(submissions, request_type)
    Request.find_all_by_submission_id(submissions.map(&:id), :conditions => ["request_type_id = #{request_type.id}"])
  end
  
  def submissions_from_requests(requests)
    requests.map{ |request| request.submission }.uniq
  end
  
end
