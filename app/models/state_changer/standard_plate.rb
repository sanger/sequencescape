# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of a standard plate
  class StandardPlate < StateChanger::Base
    # Updates the state of the labware to the target state.  The basic implementation does this by updating
    # all of the TransferRequest instances to the state specified.  If contents is blank then the change is assumed to
    # relate to all wells of the plate, otherwise only the selected ones are updated.
    # @return [Void]
    def update_labware_state
      broadcast_library_start unless %w[failed cancelled].include?(target_state)
      update_transfer_requests
      fail_associated_requests if target_state == 'failed'
    end

    private

    def _receptacles
      labware.wells.includes(
        :aliquot_requests,
        transfer_requests_as_target: [
          { associated_requests: %i[request_type request_events] },
          :target_aliquot_requests
        ]
      )
    end

    def receptacles
      @receptacles ||= contents.present? ? _receptacles.located_at(contents) : _receptacles
    end

    # Record the start of library creation for the plate
    def broadcast_library_start
      generate_events_for(pending_orders)
    end

    def pending_orders
      associated_requests.select(&:pending?).pluck(:order_id)
    end

    def generate_events_for(orders)
      orders.each do |order_id|
        BroadcastEvent::LibraryStart.create!(seed: labware, user: user, properties: { order_id: order_id })
      end
    end

    def update_transfer_requests
      receptacles.each do |w|
        w.transfer_requests_as_target.each { |r| r.transition_to(target_state) }
      end
    end

    def fail_associated_requests
      associated_requests.each do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.passed? ? request.retrospective_fail! : request.fail!
      end
    end

    # Pulls out the customer requests associated with the wells.
    # Note: Do *NOT* go through labware here, as you'll pull out all requests
    # not just those associated with the wells in the 'contents' array
    def associated_requests
      receptacles.flat_map(&:aliquot_requests)
    end
  end
end
