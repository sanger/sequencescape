# frozen_string_literal: true
module Request::GroupingHelpers
  def group_requests_by_submission_id(requests)
    # NOTE: Not using group_by(&:submission_id) to maintain the order of the submissions from the order of the requests
    requests
      .inject(Hash.new { |h, k| h[k] = [] }) do |groups, request|
        groups.tap { groups[request.submission_id] << request }
      end
      .values
  end
end
