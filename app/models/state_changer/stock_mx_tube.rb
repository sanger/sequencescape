# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of the {Tube::StockMx} purpose tubes
  # @note As of 2019-10-01 only used for 'Standard MX' and 'Tag Stock-MX' tubes (Gatekeeper)
  class StockMxTube < StateChanger::TubeBase
    # This state changer maps *all* state changes directly on to the
    # associated request
    self.map_target_state_to_associated_request_state = Hash.new { |_h, i| i }

    private

    def associated_requests
      labware.requests_as_target.opened
    end

    def transfer_requests
      labware.transfer_requests_as_target
    end

    def update_associated_requests
      associated_requests.each do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.transition_to(target_state)
      end
    end
  end
end
