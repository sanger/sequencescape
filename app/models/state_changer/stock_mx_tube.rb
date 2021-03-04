# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of the Tube::StockMx purpose tubes
  class StockMxTube < StateChanger::Base
    # Updates the state of the labware to the target state.  The basic implementation does this by updating
    # all of the TransferRequest instances to the state specified.  If contents is blank then the change is assumed to
    # relate to all wells of the plate, otherwise only the selected ones are updated.
    # @return [Void]
    def update_labware_state
      transition_customer_requests
      update_transfer_requests
    end

    private

    def update_transfer_requests
      labware.transfer_requests_as_target.each do |request|
        request.transition_to(target_state)
      end
    end

    def transition_customer_requests
      labware.requests_as_target.opened.each do |request|
        request.transition_to(target_state)
      end
    end
  end
end
