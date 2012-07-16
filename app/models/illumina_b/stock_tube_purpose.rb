class IlluminaB::StockTubePurpose < Tube::Purpose
  def create_with_request_options(tube)
    raise 'Unimplemented behaviour'
  end

  def transition_to(tube, state, _ = nil)
    tube.requests_as_target.open.each do |request|
      request.transition_to(state)
    end
  end
end
