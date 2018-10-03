class IlluminaHtp::InitialStockTubePurpose < IlluminaHtp::StockTubePurpose
  def valid_transition?(outer_request, target_state)
    target_state != 'started' || outer_request.pending?
  end

  def transition_to(tube, state, _user, _ = nil, customer_accepts_responsibility = false)
    ActiveRecord::Base.transaction do
      tube.transfer_requests_as_target.where.not(state: terminated_states).find_each do |request|
        request.transition_to(state)
        next unless request.outer_request.present?
        new_outer_state = ['started', 'passed', 'qc_complete'].include?(state) ? 'started' : state
        request.outer_request.customer_accepts_responsibility! if customer_accepts_responsibility
        request.outer_request.transition_to(new_outer_state)   if valid_transition?(request.outer_request, new_outer_state)
      end
    end
  end

  ##
  # We find sibling tubes by first finding the outer request type (library completion) and the transfer request class
  # We find all outer requests of the same type in the submission, and match these up with the transfer requests
  # The RIGHT OUTER JOIN ensures we have a null result for any outer requests which don't have matching transfer requests
  # We only pick up open requests, just in case a whole tube has failed / been cancelled.
  def sibling_tubes(tube)
    return [] if tube.submission.nil?
    submission_id = tube.submission.id

    siblings = Tube.select('assets.*, tfr.state AS quick_state').distinct.joins([
      'LEFT JOIN transfer_requests AS tfr ON tfr.target_asset_id = assets.id',
      'RIGHT OUTER JOIN requests AS outr ON outr.asset_id = tfr.asset_id AND outr.asset_id IS NOT NULL',
      'LEFT JOIN request_types AS rt ON rt.id = outr.request_type_id'
    ])
                   .where(
                     outr: { submission_id: submission_id, state: Request::Statemachine::OPENED_STATE },
                     tfr:  { submission_id: submission_id, state: TransferRequest::ACTIVE_STATES },
                     rt:   { for_multiplexing: true }
                   )
                   .includes(:uuid_object, :barcodes)

    siblings.map { |s| s.id.nil? ? :no_tube : { name: s.name, uuid: s.uuid, ean13_barcode: s.ean13_barcode, state: s.quick_state } }
  end
end
