class Tube::StockMx < Tube::Purpose
  def transition_to(tube, state, _user, _ = nil, _customer_accepts_responsibility = false)
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
