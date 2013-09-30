module PipelinesHelper
  def next_pipeline_name_for(request)
    submission         = request.submission or return nil
    first_next_request = submission.next_requests(request).first or return nil
    first_next_request.request_type.name
  end

  def target_purpose_for(request)
    nrs = request.submission.present? ? request.submission.next_requests(request) : []
    return nrs.first.request_type.acceptable_plate_purposes.map(:name).join('|') unless nrs.empty?
    return request.request_metadata.target_purpose.name if request.request_metadata.target_purpose.present?
    return 'Not specified'
  end
end
