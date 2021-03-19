# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of initial stock tubes within the library prep process
  class InitialStockTube < StateChanger::TubeBase
    TERMINATED_STATES = %w[cancelled failed].freeze

    # This behaviour is actually wrong. Doing refactor first, will fix in later commit
    self.map_target_state_to_associated_request_state = (Hash.new { |_h, i| i }).merge({
                                                                                         'failed' => 'failed',
                                                                                         'cancelled' => nil,
                                                                                         'started' => 'started',
                                                                                         'passed' => 'started',
                                                                                         'qc_complete' => 'started'
                                                                                       })

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
