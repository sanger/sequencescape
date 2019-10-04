require_dependency 'tube/purpose'

# {Tube::Purpose} for standard {MultiplexedLibraryTube multiplexed library tubes}.
# Used in the legacy {Pipeline pipelines} and in non-pipeline processes such as
# {Pooling}. Represents one or more tagged libraries in a tube together, suitable
# for Sequencing.
# @note As of 201-10-01 only used for 'Standard MX' and 'Tag MX' tubes (Gatekeeper)
class Tube::StandardMx < Tube::Purpose
  # Transitioning an MX library tube to a state involves updating the state of the transfer requests.  If the
  # state is anything but "started" or "pending" then the pulldown library creation request should also be
  # set to the same state
  # Called via Tube#transition_to
  # Updates the state of tube to state
  # @param tube [Tube] The tube being updated
  # @param state [String] The desired target state
  # @param _user [User] Provided for interface compatibility (The user performing the action)
  # @param _ [nil, Array] Provided for interface compatibility
  # @param _customer_accepts_responsibility [Boolean] The customer has proceeded against advice and will be charged
  #                                                   for failures (Provided for compatibility)
  #
  # @return [Void]
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
    !%w[started pending].include?(state)
  end
end
