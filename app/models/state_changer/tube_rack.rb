# frozen_string_literal: true
module StateChanger
  # Handles the basic transitions of a tube rack
  class TubeRack < StateChanger::Base
    PASSED_TARGET_STATE = %w[passed].freeze
    TRANSFER_REQUEST_FILTER_STATES = %w[failed cancelled].freeze

    # Follows app/models/state_changer/tube_base.rb.
    # Updates the state of all labware associated with the tube rack.
    #
    # Iterates through all racked tubes in the labware and updates their
    # associated requests and transfer requests.
    #
    # @return [void]
    def update_labware_state
      labware.racked_tubes.each do |racked_tube|
        # Do we need to invoke update_associated_requests for state transfers?
        update_transfer_requests(racked_tube, target_state)
      end
    end

    private

    # Updates the state of transfer requests for a given racked tube.
    #
    # Finds all transfer requests targeting the tube that are not in the 'failed' state
    # and transitions them to the target state.
    #
    # @param racked_tube [RackedTube] The racked tube whose transfer requests are to be updated.
    # @param target_state [String] The target state for a transfer request
    # @return [void]
    def update_transfer_requests(racked_tube, target_state)
      transfer_requests = racked_tube.tube.transfer_requests_as_target
      if PASSED_TARGET_STATE.include?(target_state)
        transfer_requests = transfer_requests.where.not(state: TRANSFER_REQUEST_FILTER_STATES)
      end
      transfer_requests.find_each { |request| request.transition_to(target_state) }
    end
  end
end
