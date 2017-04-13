# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class CherrypickForPulldownPipeline < CherrypickingPipeline
  include Pipeline::InboxGroupedBySubmission

  self.display_next_pipeline = true

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

  # Validates that the requests in the batch lead into the same pipeline.
  def validation_of_requests(requests, &block)
    super # Could throw, which means that the rest of this function does not get executed

    yield('cannot be mixed across pulldown pipelines') if requests.map do |request|
      request.submission.next_requests(request).map(&:request_type)
    end.flatten.uniq.size > 1
  end
end
