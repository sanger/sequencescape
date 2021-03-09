# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of the {Tube::StandardMx} purpose tubes
  # @note As of 201-10-01 only used for 'Standard MX' and 'Tag MX' tubes (Gatekeeper)
  class StandardMxTube < StateChanger::TubeBase
    private

    def update_associated_requests
      return unless update_all_requests?

      labware.requests_as_target.opened.for_billing.each do |request|
        request.transition_to(target_state)
      end
    end

    def transfer_requests
      labware.transfer_requests_as_target
    end

    def update_all_requests?
      %w[started pending cancelled].exclude?(target_state)
    end
  end
end
