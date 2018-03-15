# frozen_string_literal: true

# MixedSubmissioMX tubes can contain aliquots produced under
# multiple submissions. This disrupts the usual means of looking
# up the customer requests, as transfer requests effectively belong
# to multiple submissions.
# Ultimately we probably want to look at eliminating these classes
# and to unify their behaviour under a standard class.
class Tube::MixedSubmissionMx < Tube::Purpose
  def transition_to(tube, state, _user, _ = nil, _customer_accepts_responsibility = false)
    tube.transfer_requests_as_target.opened.each do |request|
      request.transition_to(state)
    end
    tube.requests_as_target.opened.each do |request|
      request.transition_to(state)
    end
  end

  def pool_id(tube)
    tube.submission.try(:id)
  end

  def name_for_child_tube(tube)
    tube.name
  end
end
