class IlluminaC::StockPurpose < PlatePurpose
  include PlatePurpose::Stock

  def transition_to(plate, state, _user, contents = nil, _customer_accepts_responsibility = false)
    return unless ['failed', 'cancelled'].include?(state)
    plate.wells.located_at(contents).include_requests_as_target.include_requests_as_source.each do |well|
      well.requests.each { |r| r.send(transition_from(r.state)) if r.is_a?(IlluminaC::Requests::LibraryRequest) && transition_from(r.state) }
      well.transfer_requests_as_target.each { |r| r.transition_to('failed') }
    end
  end

  private

  def transition_from(state)
    { 'pending' => :cancel_before_started!, 'started' => :cancel! }[state]
  end

  def calculate_state_of_well(wells_states)
    cancelled = wells_states.delete('cancelled') if wells_states.count > 1
    return wells_states.first if wells_states.one?
    return :unready if wells_states.size > 1
    cancelled || :unready
  end
end
