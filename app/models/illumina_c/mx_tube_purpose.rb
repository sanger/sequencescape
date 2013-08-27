class IlluminaC::MxTubePurpose < IlluminaHtp::MxTubePurpose
  def created_with_request_options(tube)
    tube.requests_as_target.where_is_a?(IlluminaC::Requests::LibraryRequest).first.request_options_for_creation || {}
  end

  def stock_plate(tube)
    tube.requests_as_target.where_is_a?(IlluminaC::Requests::LibraryRequest).first.asset.plate
  end

  def request_state(request,state)
    state
  end
  private :request_state
end
