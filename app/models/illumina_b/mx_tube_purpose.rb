class IlluminaB::MxTubePurpose < Tube::Purpose
  def created_with_request_options(tube)
    tube.requests_as_target.where_is_a?(IlluminaB::Requests::StdLibraryRequest).first.request_options_for_creation || {}
  end

  def transition_to(tube, state, _ = nil)
    update_all_requests = ![ 'started', 'pending' ].include?(state)
    tube.requests_as_target.open.for_billing.each do |request|
      request.transition_to(state) if update_all_requests or request.is_a?(TransferRequest)
    end
  end

  def stock_plate(tube)
    tube.requests_as_target.where_is_a?(IlluminaB::Requests::StdLibraryRequest).first.asset.plate
  end
end
