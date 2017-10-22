require_dependency 'tube/purpose'
class Tube::StandardMx < Tube::Purpose
  def created_with_request_options(tube)
    tube.parent.try(:created_with_request_options) || {}
  end

  # Transitioning an MX library tube to a state involves updating the state of the transfer requests.  If the
  # state is anything but "started" or "pending" then the pulldown library creation request should also be
  # set to the same state
  def transition_to(tube, state, _user, _ = nil, _customer_accepts_responsibility = false)
    update_all_requests = !['started', 'pending'].include?(state)
    tube.requests_as_target.opened.for_billing.each do |request|
      request.transition_to(state) if update_all_requests or request.is_a?(TransferRequest)
    end
  end
end
