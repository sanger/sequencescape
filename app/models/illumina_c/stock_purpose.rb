class IlluminaC::StockPurpose < PlatePurpose
  include PlatePurpose::Stock

  # Updates the state of plate to state
  # @param plate [Plate] The plate being updated
  # @param state [String] The desired target state
  # @param user [User] The person to associate with the action (Will take ownership of the plate)
  # @param contents [nil, Array] Array of well locations to update, leave nil for ALL wells
  # @param customer_accepts_responsibility [Boolean] The customer proceeded against advice and will still be charged
  #                                                  in the the event of a failure
  #
  # @return [Void]
  def transition_to(plate, state, _user, contents = nil, _customer_accepts_responsibility = false)
    return unless %w[failed cancelled].include?(state)

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
