# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2013,2015 Genome Research Ltd.

module PipelinesHelper
  def next_pipeline_name_for(request)
    submission         = request.submission or return nil
    first_next_request = submission.next_requests(request).first or return nil
    first_next_request.request_type.name
  end

  def target_purpose_for(request)
    nrs = request.submission.present? ? request.submission.next_requests(request) : []
    return nrs.first.request_type.acceptable_plate_purposes.pluck(:name).join('|') unless nrs.empty?
    request.target_purpose.try(:name) || 'Not specified'
  end

  def fluidigm_target?(batch)
    batch.requests.where_is_a?(CherrypickForFluidigmRequest).present?
  end
end
