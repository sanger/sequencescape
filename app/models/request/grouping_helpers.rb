#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
module Request::GroupingHelpers
  def group_requests_by_submission_id(requests)
    # NOTE: Not using group_by(&:submission_id) to maintain the order of the submissions from the order of the requests
    requests.inject(ActiveSupport::OrderedHash.new { |h,k| h[k] = [] }) do |groups, request|
      groups.tap { groups[request.submission_id] << request }
    end.values
  end
end
