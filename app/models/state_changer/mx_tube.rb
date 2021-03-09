# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of the high throughput multiplexed library tube
  # {IlluminaHtp::MxTubePurpose} this is the tube at the end of the pipelines
  class MxTube < StateChanger::Base
    private

    def transfer_requests
      labware.transfer_requests_as_target
    end

    def update_associated_requests
      return unless update_associated_requests?

      # @note map.uniq is actually about twice as fast as a set for the kind of data we're expecting to see
      orders = associated_requests.map do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.transition_to(target_state)
        # Grab the order ids
        request.order_id
      end.uniq

      generate_events_for(orders) if target_state == 'passed'
    end

    def associated_requests
      labware.requests_as_target.for_billing.opened
    end

    def update_associated_requests?
      %w[failed passed].include?(target_state)
    end

    def generate_events_for(orders)
      orders.each do |order_id|
        BroadcastEvent::LibraryComplete.create!(seed: labware, user: user, properties: { order_id: order_id })
      end
    end
  end
end
