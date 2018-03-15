require_dependency 'tube/purpose'
class Tube::StandardMx < Tube::Purpose
  # Transitioning an MX library tube to a state involves updating the state of the transfer requests.  If the
  # state is anything but "started" or "pending" then the pulldown library creation request should also be
  # set to the same state
  def transition_to(tube, state, _user, _ = nil, _customer_accepts_responsibility = false)
    if update_all_requests?(state)
      tube.requests_as_target.opened.for_billing.each do |request|
        request.transition_to(state)
      end
    end
    tube.transfer_requests_as_target.each do |request|
      request.transition_to(state)
    end
  end

  private

  def update_all_requests?(state)
    !['started', 'pending'].include?(state)
  end
end
