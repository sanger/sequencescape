# frozen_string_literal: true

module StateChanger
  # Handles the basic transitions of a standard plate
  class StandardPlate < StateChanger::Base
    # Target_state of failed will fail associated requests only.
    # All other transitions will be ignored.
    self.map_target_state_to_associated_request_state = { 'failed' => 'failed' }

    # Updates the state of the labware to the target state.  The basic implementation does this by updating
    # all of the TransferRequest instances to the state specified.  If {#contents} is blank then the change is assumed
    # to relate to all wells of the plate, otherwise only the selected ones are updated.
    # @return [Void]
    def update_labware_state
      broadcast_library_start unless %w[failed cancelled].include?(target_state)
      update_transfer_requests
      update_associated_requests if associated_request_target_state
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
      associated_requests.select(&:pending?).pluck(:order_id).uniq
    end

    def generate_events_for(orders)
      orders.each do |order_id|
        BroadcastEvent::LibraryStart.create!(seed: labware, user: user, properties: { order_id: order_id })
      end
    end

    def update_transfer_requests
      transfer_requests.each do |request|
        # skip state update if request already in that state
        next if request.state == target_state
        request.transition_to(target_state)
      end
    end

    def update_associated_requests
      raise_request_error if associated_requests.empty? && associated_submission?

      associated_requests.each do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility

        # skip state update if request already in that state
        next if request.state == associated_request_target_state
        request.transition_to(associated_request_target_state)
      end
    end

    def transfer_requests
      receptacles.flat_map(&:transfer_requests_as_target)
    end

    # Pulls out the customer requests associated with the wells.
    # Note: Do *NOT* go through labware here, as you'll pull out all requests
    # not just those associated with the wells in the 'contents' array
    def associated_requests
      receptacles.flat_map(&:aliquot_requests)
    end

    # Checks if the transfer requests have an associated submission, and thus
    # we could expect to find outer requests. This check is purely to support
    # the assertion below, and blow up noisily if something looks suspect.
    def associated_submission?
      transfer_requests.any?(&:submission_id)
    end

    # Older aliquots do not have request set. Failing them should be a rare
    # scenario. We'll blow up noisily for now, and will consider automatic
    # repair if we run into this more often then we are expecting.
    # This also covers other scenarios where we don't find the outer requests
    def raise_request_error
      raise StandardError, 'Could not find requests for wells.'
    end
  end
end
