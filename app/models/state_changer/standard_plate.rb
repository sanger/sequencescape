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

    def receptacles
      contents.present? ? labware.wells.located_at(contents) : labware.wells
    end

    # Record the start of library creation for the plate
    def broadcast_library_start
      generate_events_for(pending_orders)
    end

    def pending_orders
      labware.in_progress_requests.pending.distinct.pluck(:order_id)
    end

    def generate_events_for(orders)
      orders.each do |order_id|
        BroadcastEvent::LibraryStart.create!(seed: labware, user: user, properties: { order_id: order_id })
      end
    end

    def update_transfer_requests
      wells = receptacles.includes(
        transfer_requests_as_target: [
          { associated_requests: %i[request_type request_events] },
          :target_aliquot_requests
        ]
      )
      wells.each do |w|
        w.transfer_requests_as_target.each { |r| r.transition_to(target_state) }
      end
    end

    def fail_associated_requests
      # Load all of the requests that come from the stock wells that should be failed.  Note that we can't simply change
      # their state, we have to actually use the statemachine method to do this to get the correct behaviour.
      queries = []

      # Build a query per well
      fail_request_details_for do |submission_ids, stock_wells|
        queries << Request.where(asset_id: stock_wells, submission_id: submission_ids)
      end
      raise 'Apparently there are not requests on these wells?' if queries.empty?

      # Here we chain together our various request scope using or, allowing us to retrieve them in a single query.
      request_scope = queries.reduce(queries.pop) { |scope, query| scope.or(query) }
      request_scope.each do |request|
        request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.passed? ? request.retrospective_fail! : request.fail!
      end
    end

    # Override this method to control the requests that should be failed for the given wells.
    def fail_request_details_for
      receptacles.each do |well|
        submission_ids = well.transfer_requests_as_target.map(&:submission_id)
        next if submission_ids.empty?

        stock_wells = well.stock_wells.map(&:id)
        next if stock_wells.empty?

        yield(submission_ids, stock_wells)
      end
    end
  end
end
