class IlluminaC::QcPoolPurpose < Tube::Purpose
  def transition_to(tube, state, _user, _ = nil, _customer_accepts_responsibility = false)
    ActiveRecord::Base.transaction do
      tube.transfer_requests_as_target.where.not(state: terminated_states).find_each do |request|
        request.transition_to(state)
      end
    end
  end

  def terminated_states
    ['cancelled', 'failed']
  end
  private :terminated_states
end
