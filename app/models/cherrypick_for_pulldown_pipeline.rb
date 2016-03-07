#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
class CherrypickForPulldownPipeline < CherrypickingPipeline
  include Pipeline::InboxGroupedBySubmission

  def display_next_pipeline?
    true
  end

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
    requests = Request.where(:id=>request_ids).includes(:submission).all
    expected_requests = all_request_from_submissions_filtered_by_request_type(submissions_from_requests(requests),requests.first.request_type)
    return true if requests.size == expected_requests.size

    false
  end

  def all_request_from_submissions_filtered_by_request_type(submissions, request_type)
    Request.find_all_by_submission_id(submissions.map(&:id), :conditions => ["request_type_id = #{request_type.id}"])
  end
  private :all_request_from_submissions_filtered_by_request_type

  def submissions_from_requests(requests)
    requests.map{ |request| request.submission }.uniq
  end
  private :submissions_from_requests

  # Validates that the requests in the batch lead into the same pipeline.
  def validation_of_requests(requests, &block)
    super  # Could throw, which means that the rest of this function does not get executed

    yield('cannot be mixed across pulldown pipelines') if requests.map do |request|
      request.submission.next_requests(request).map(&:request_type)
    end.flatten.uniq.size > 1
  end
end
