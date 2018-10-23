class Tube::StockMx < Tube::Purpose
  def transition_to(tube, state, _user, _ = nil, _customer_accepts_responsibility = false)
    tube.transfer_requests_as_target.each do |request|
      request.transition_to(state)
    end
    tube.requests_as_target.opened.each do |request|
      request.transition_to(state)
    end
  end

  def name_for_child_tube(tube)
    tube.name
  end
end
