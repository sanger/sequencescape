module Request::GroupingHelpers
  extend self

  def group_requests_by_submission_id(requests)
    # NOTE: Not using group_by(&:submission_id) to maintain the order of the submissions from the order of the requests
    requests.inject(ActiveSupport::OrderedHash.new { |h,k| h[k] = [] }) do |groups, request|
      groups.tap { groups[request.submission_id] << request }
    end.values
  end

  def sort_grouped_requests_by_submission_id(requests)
    group_requests_by_submission_id(requests).map do |requests_in_a_submission|
      requests_in_a_submission.sort { |a,b| a.asset.map_id <=> b.asset.map_id }
    end.flatten
  end
end
