module PipelinesHelper
  def next_pipeline_name_for(request)
    submission         = request.submission or return nil
    first_next_request = submission.next_requests(request).first or return nil
    first_next_request.request_type.name
  end
end
