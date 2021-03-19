# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of the {Tube::StandardMx} purpose tubes
  # @note As of 2019-10-01 only used for 'Standard MX' and 'Tag MX' tubes (Gatekeeper)
  class StandardMxTube < StateChanger::TubeBase
    self.map_target_state_to_associated_request_state = {
      'failed' => 'failed',
      'passed' => 'passed'
    }

    private

    def associated_requests
      labware.requests_as_target.opened.for_billing
    end

    def transfer_requests
      labware.transfer_requests_as_target
    end

    def update_associated_requests
      associated_requests.each do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.transition_to(associated_request_target_state)
      end
    end
  end
end
