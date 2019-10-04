# Class initially used to represent the first tube in a pipeline following pooling
# from a plate. However appears to be a little more widespread in Limber pipelines.
# eg. LB Custom Pool Norm
class IlluminaHtp::InitialStockTubePurpose < IlluminaHtp::StockTubePurpose
  def valid_transition?(outer_request, target_state)
    target_state != 'started' || outer_request.pending?
  end

  # Called via Tube#transition_to
  # Updates the state of tube to state
  # @param tube [Tube] The tube being updated
  # @param state [String] The desired target state
  # @param _user [User] Provided for interface compatibility (The user performing the action)
  # @param _ [nil, Array] Provided for interface compatibility
  # @param customer_accepts_responsibility [Boolean] The customer has proceeded against
  #                                                  advice and will be charged for failures
  #
  # @return [Void]
  def transition_to(tube, state, _user, _ = nil, customer_accepts_responsibility = false)
    ActiveRecord::Base.transaction do
      tube.transfer_requests_as_target.where.not(state: terminated_states).find_each do |request|
        request.transition_to(state)
        next if request.outer_request.blank?
        next if state == 'cancelled'

        new_outer_state = %w[started passed qc_complete].include?(state) ? 'started' : state
        request.outer_request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.outer_request.transition_to(new_outer_state)   if valid_transition?(request.outer_request, new_outer_state)
      end
    end
  end

  # Returns a summary of all related tube in the submission.
  # Limitation: doesn't understand pipelines, so just returns the tube at the head of the graph.
  # This isn't necessarily the one the users actually want, but we CAN validate that in Limber.
  # Additionally this will run into trouble if we end up wanting to use a tube earlier in the graph
  # (Such as following the introduction of a QC tube). Given that this will require knowledge of
  # the pipeline though, this logic is best shifted out into Limber.
  # TODO: Make tis decision in Limber, then strip out this code.
  def sibling_tubes(tube)
    return [] if tube.submission.nil?

    # Find all requests that are being pooled together
    sibling_requests = tube.submission.requests.multiplexed.opened.ids

    sibling_tubes = Tube.joins(:transfer_requests_as_target)
                        .includes(:transfer_requests_as_source) # Outer join, as we don't want these
                        .where(transfer_requests: { submission_id: tube.submission }) # find out tubes via transfer requests
                        .where("transfer_requests_as_sources_#{Tube.table_name}": { id: nil }) # Make sure we have no transfers out of the tube
                        .where.not(transfer_requests: { state: 'cancelled' }) # Filter out any cancelled tubes
                        .includes(:uuid_object, :barcodes, :aliquots) # Load the stuff we need for the hash

    # Find all requests in the tubes we've found
    found_requests = sibling_tubes.flat_map { |sibling| sibling.aliquots.map(&:request_id) }

    # Check if there are any requests we haven't found, so we know there are still some in-progress tubes.
    pending_requests = (sibling_requests - found_requests).present?

    tube_array = sibling_tubes.map { |s| { name: s.name, uuid: s.uuid, ean13_barcode: s.ean13_barcode, state: s.state } }
    tube_array << :no_tube if pending_requests
    tube_array
  end
end
