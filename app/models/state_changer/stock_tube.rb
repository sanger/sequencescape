# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of stock tubes within the library prep process
  class StockTube < StateChanger::TubeBase
    TERMINATED_STATES = %w[cancelled failed].freeze

    self.map_target_state_to_associated_request_state = {
      'failed' => 'failed'
    }

    private

    def associated_requests
      labware.in_progress_requests
    end

    def transfer_requests
      @transfer_requests ||= labware.transfer_requests_as_target
                                    .where.not(state: TERMINATED_STATES)
    end

    def update_associated_requests
      associated_requests.each do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.transition_to(target_state)
      end
    end
  end
end
