class IlluminaHtp::MxTubePurpose < Tube::Purpose
  def created_with_request_options(tube)
    tube.requests_as_target.where_is_a?(IlluminaHtp::Requests::StdLibraryRequest).first.request_options_for_creation || {}
  end

  def transition_to(tube, state, _ = nil)
    target_requests(tube).each do |request|
      to_state = request_state(request,state)
      request.transition_to(to_state) unless to_state.nil?
    end
  end

  def target_requests(tube)
    tube.requests_as_target.for_billing.all(
      :conditions=>[
        "state IN (?) OR (state='passed' AND sti_type IN (?))",
        Request::Statemachine::OPENED_STATE,
        Class.subclasses_of(TransferRequest).map(&:to_s)
      ])
  end
  private :target_requests

  def stock_plate(tube)
    tube.requests_as_target.where_is_a?(IlluminaHtp::Requests::StdLibraryRequest).first.asset.plate
  end

  def request_state(request,state)
    mappings = {'cancelled' =>'cancelled','failed' => 'failed','qc_complete' => 'passed'}
    request.is_a?(TransferRequest) ? state : mappings[state]
  end
  private :request_state

end
