# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of initial stock tubes within the library prep process
  class InitialStockTube < StateChanger::TubeBase
    TERMINATED_STATES = %w[cancelled failed].freeze

    # Most activity should start the outer request, with the exception of 'fail'
    # which should fail it, and cancel, which should do nothing. We don't expect
    # to see a transition to pending, but in the unlikely case we do, this should
    # also be ignored.
    self.map_target_state_to_associated_request_state = {
      'failed' => 'failed',
      'cancelled' => nil,
      'pending' => nil
    }.tap { |h| h.default = 'started' }

    def update_associated_requests
      associated_requests.each do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.transition_to(associated_request_target_state) if valid_transition?(request)
      end
    end

    private

    def associated_requests
      transfer_requests.filter_map(&:outer_request)
    end

    def transfer_requests
      @transfer_requests ||= labware.transfer_requests_as_target
                                    .where.not(state: TERMINATED_STATES)
                                    .include_for_request_state_change
    end

    def valid_transition?(outer_request)
      associated_request_target_state != 'started' || outer_request.pending?
    end
  end
end
