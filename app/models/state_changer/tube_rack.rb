# frozen_string_literal: true
module StateChanger
  # Handles the basic transitions of a tube rack
  class TubeRack < StateChanger::Base
    # Follows app/models/state_changer/tube_base.rb.
    # Updates the state of all labware associated with the tube rack.
    #
    # Iterates through all racked tubes in the labware and updates their
    # associated requests and transfer requests.
    #
    # @return [void]
    def update_labware_state
      labware.racked_tubes.each do |racked_tube|
        update_associated_requests(racked_tube)
        update_transfer_requests(racked_tube)
      end
    end

    private

    # Updates the state of associated requests for a given racked tube.
    #
    # Finds all in-progress requests for the tube that are not in the 'passed' state
    # and transitions them to the target state. If `customer_accepts_responsibility`
    # is true, it also marks the request as accepted by the customer.
    #
    # @param racked_tube [RackedTube] The racked tube whose associated requests are to be updated.
    # @return [void]
    def update_associated_requests(racked_tube)
      racked_tube
        .tube
        .in_progress_requests
        .where.not(state: ['passed'])
        .find_each do |request|
          request.customer_accepts_responsibility! if customer_accepts_responsibility
          request.transition_to(target_state)
        end
    end

    # Updates the state of transfer requests for a given racked tube.
    #
    # Finds all transfer requests targeting the tube that are not in the 'failed' state
    # and transitions them to the target state.
    #
    # @param racked_tube [RackedTube] The racked tube whose transfer requests are to be updated.
    # @return [void]
    def update_transfer_requests(racked_tube)
      racked_tube
        .tube
        .transfer_requests_as_target
        .where.not(state: ['failed'])
        .find_each { |request| request.transition_to(target_state) }
    end
  end
end
