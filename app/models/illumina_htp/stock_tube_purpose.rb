# Represents a prepared library or multiplexed library which is
# still undergoing normalization, or is at a higher concentration than is
# required for {SequencingPipeline}. A stock may be stored to return to later
# is more material is required. (Although in practice the Lims doesn't always make)
# this as easy as it should.
# Used by external applications.
class IlluminaHtp::StockTubePurpose < Tube::Purpose
  def create_with_request_options(_tube)
    raise 'Unimplemented behaviour'
  end

  # Called via Tube#transition_to
  # Updates the state of tube to state
  # @param tube [Tube] The tube being updated
  # @param state [String] The desired target state
  # @param _user [User] Provided for interface compatibility (The user performing the action)
  # @param _ [nil, Array] Provided for interface compatibility
  # @param customer_accepts_responsibility [Boolean] The customer has proceeded against
  #                                                  advice and will be charged for failures
  #
  # @return [Void]
  def transition_to(tube, state, _user, _ = nil, customer_accepts_responsibility = false)
    tube.transfer_requests_as_target.where.not(state: terminated_states).find_each do |request|
      request.transition_to(state)
    end
    outer_requests_for(tube).each do |request|
      request.customer_accepts_responsibility! if customer_accepts_responsibility
      request.transition_to(state)
    end if terminated_states.include?(state)
  end

  def outer_requests_for(tube)
    tube.requests_as_target.map do |r|
      r.submission.requests.where_is_a(LibraryCompletion)
    end.uniq
  end

  def terminated_states
    %w[cancelled failed]
  end
  private :terminated_states

  def stock_plate(tube)
    return nil if tube.transfer_requests_as_target.empty?

    assets = [tube.transfer_requests_as_target.first.asset]
    until assets.empty?
      asset = assets.shift
      return asset.plate if asset.is_a?(Well) and asset.plate.stock_plate?

      assets.push(asset.transfer_requests_as_target.first.asset).compact
    end

    raise "Cannot locate stock plate for #{tube.display_name.inspect}"
  end

  def stock_wells(tube)
    tube.requests_as_target.map do |request|
      request.asset.stock_wells
    end.flatten
  end
end
