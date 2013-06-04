class IlluminaC::QcPoolPurpose < Tube::Purpose

  def transition_to(tube, state, _ = nil)
    ActiveRecord::Base.transaction do
      tube.requests_as_target.all(not_terminated).each do |request|
        request.transition_to(state)
      end
    end
  end

  def not_terminated
    {:conditions=>[ 'state NOT IN (?)',['cancelled','failed','aborted']]}
  end
  private :not_terminated

end
