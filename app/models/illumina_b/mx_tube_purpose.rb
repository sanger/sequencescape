class IlluminaB::MxTubePurpose < IlluminaHtp::MxTubePurpose
  def stock_plate(tube)
    tube.requests_as_target.where_is_a?(IlluminaB::Requests::StdLibraryRequest).first.asset.plate
  end

  def request_state(request,state)
    state
  end
  private :request_state
end
