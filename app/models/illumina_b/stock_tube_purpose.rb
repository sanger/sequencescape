class IlluminaB::StockTubePurpose < Tube::Purpose
  def create_with_request_options(tube)
    raise 'Unimplemented behaviour'
  end

  def transition_to(tube, state, _ = nil)
    tube.requests_as_target.all(not_terminated).each do |request|
      request.transition_to(state)
    end
  end

  def not_terminated
    {:conditions=>[ 'state NOT IN (?)',['cancelled','failed','aborted']]}
  end
  private :not_terminated

  def pool_id(tube)
    tube.requests_as_target.first.submission_id
  end

  def name_for_child_tube(tube)
    tube.name
  end
end
