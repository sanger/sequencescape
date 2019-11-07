# frozen_string_literal: true

# @deprecated This class was added as part of the GBS pipeline but is now unused
# @todo #2396 Remove this file and associated factories and tests.
#
# UNUSED
#
# MixedSubmissioMX tubes can contain aliquots produced under
# multiple submissions. This disrupts the usual means of looking
# up the customer requests, as transfer requests effectively belong
# to multiple submissions.
# Ultimately we probably want to look at eliminating these classes
# and to unify their behaviour under a standard class.
class Tube::MixedSubmissionMx < Tube::Purpose
  # Called via Tube#transition_to
  # Updates the state of tube to state
  # @param tube [Tube] The tube being updated
  # @param state [String] The desired target state
  # @param _user [User] Provided for interface compatibility (The user performing the action)
  # @param _ [nil, Array] Provided for interface compatibility
  # @param _customer_accepts_responsibility [Boolean] Ignored. Provided for interface compatibility.
  #
  # @return [Void]
  def transition_to(tube, state, _user, _ = nil, _customer_accepts_responsibility = false)
    tube.transfer_requests_as_target.opened.each do |request|
      request.transition_to(state)
    end
    tube.requests_as_target.opened.each do |request|
      request.transition_to(state)
    end
  end
end
