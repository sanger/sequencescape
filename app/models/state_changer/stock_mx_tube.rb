# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of the {Tube::StockMx} purpose tubes
  # @note As of 201-10-01 only used for 'Standard MX' and 'Tag Stock-MX' tubes (Gatekeeper)
  class StockMxTube < StateChanger::TubeBase
    private

    def transfer_requests
      labware.transfer_requests_as_target
    end

    def update_associated_requests
      labware.requests_as_target.opened.each do |request|
        request.transition_to(target_state)
      end
    end
  end
end
