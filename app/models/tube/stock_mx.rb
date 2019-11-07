# Used in the legacy {Pipeline pipelines} and in non-pipeline processes such as
# {Pooling}. Represents one or more tagged libraries in a tube together, which have
# either not been normalised for sequencing, or are being held in reserve.
# @note As of 201-10-01 only used for 'Standard MX' and 'Tag Stock-MX' tubes (Gatekeeper)
class Tube::StockMx < Tube::Purpose
  # Called via Tube#transition_to
  # Updates the state of tube to state
  # @param tube [Tube] The tube being updated
  # @param state [String] The desired target state
  # @param _user [User] Provided for interface compatibility (The user performing the action)
  # @param _ [nil, Array] Provided for interface compatibility
  # @param _customer_accepts_responsibility [Boolean] Provided for interface compatibility
  #
  # @return [Void]
  def transition_to(tube, state, _user, _ = nil, _customer_accepts_responsibility = false)
    tube.transfer_requests_as_target.each do |request|
      request.transition_to(state)
    end
    tube.requests_as_target.opened.each do |request|
      request.transition_to(state)
    end
  end
end
