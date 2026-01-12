# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of the high throughput multiplexed library tube
  # {IlluminaHtp::MxTubePurpose} this is the tube at the end of the pipelines
  class MxTube < StateChanger::TubeBase
    self.map_target_state_to_associated_request_state = { 'failed' => 'failed', 'passed' => 'passed' }

    private

    def associated_requests
      Rails.logger.info("app/models/state_changer/mx_tube.rb: associated_requests - calling requests_as_target")
      labware.requests_as_target.opened
    end

    def generate_events_for(orders)
      orders.each do |order_id|
        BroadcastEvent::PoolReleased.create!(seed: labware, user: user, properties: { order_id: })
      end
    end

    def transfer_requests
      labware.transfer_requests_as_target
    end

    def update_associated_requests
      # @note map.uniq is actually about twice as fast as a set for the kind of data we're expecting to see
      orders =
        associated_requests
          .map do |request|
            request.customer_accepts_responsibility! if customer_accepts_responsibility
            request.transition_to(associated_request_target_state)

            # Grab the order ids
            request.order_id
          end
          .uniq

      generate_events_for(orders) if target_state == 'passed'
    end
  end
end
