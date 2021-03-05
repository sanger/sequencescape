# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of the high throughput multiplexed library tube
  class MxTube < StateChanger::Base
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
      labware.transfer_requests_as_target.each { |request| request.transition_to(target_state) }
    end

    def transition_customer_requests
      return unless customer_request_target_state

      # @note map.uniq is actually about twice as fast as a set for the kind of data we're expecting to see
      orders = customer_requests.map do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.transition_to(customer_request_target_state)
        request.order_id
      end.uniq

      generate_events_for(orders) if target_state == 'passed'
    end

    def customer_requests
      labware.requests_as_target.for_billing.where(state: Request::Statemachine::OPENED_STATE)
    end

    def customer_request_target_state
      { 'cancelled' => 'cancelled', 'failed' => 'failed', 'passed' => 'passed' }[target_state]
    end

    def generate_events_for(orders)
      orders.each do |order_id|
        BroadcastEvent::LibraryComplete.create!(seed: labware, user: user, properties: { order_id: order_id })
      end
    end
  end
end
