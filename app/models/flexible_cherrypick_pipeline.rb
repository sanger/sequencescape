# frozen_string_literal: true

# A more flexible cherrypicking pipeline that allows sample aggregation
# Hasn't been used for ages, so we can possibly lose it.
class FlexibleCherrypickPipeline < CherrypickingPipeline
  def post_finish_batch(batch, _user)
    batch.requests.with_target.includes(:request_events).find_each(&:pass!)
  end

  def post_release_batch(batch, _user)
    batch.release_pending_requests
  end

  def all_requests_from_submissions_selected?(requests)
    request_types, submissions = request_types_and_submissions_for(requests)
    matching_requests = Request.where(request_type_id: request_types, submission_id: submissions).order(:id).pluck(:id)
    requests.map(&:id).sort == matching_requests
  end

  private

  def request_types_and_submissions_for(requests)
    [requests.map(&:request_type_id).uniq, requests.map(&:submission_id).uniq]
  end
end
