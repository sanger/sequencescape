# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of the Tube::StandardMx purpose tubes
  class StandardMxTube < StateChanger::Base
    # Transitioning an MX library tube to a state involves updating the state of the transfer requests.  If the
    # state is anything but "started" or "pending" then the pulldown library creation request should also be
    # set to the same state
    def update_labware_state
      transition_customer_requests
      update_transfer_requests
    end

    private

    def transition_customer_requests
      return unless update_all_requests?

      labware.requests_as_target.opened.for_billing.each do |request|
        request.transition_to(target_state)
      end
    end

    def update_transfer_requests
      labware.transfer_requests_as_target.each do |request|
        request.transition_to(target_state)
      end
    end

    def update_all_requests?
      %w[started pending].exclude?(target_state)
    end
  end
end
