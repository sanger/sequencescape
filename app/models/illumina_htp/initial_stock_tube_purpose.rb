# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class IlluminaHtp::InitialStockTubePurpose < IlluminaHtp::StockTubePurpose
  module InitialTube
    def valid_transition?(outer_request, target_state)
      target_state != 'started' || outer_request.pending?
    end

    def transition_to(tube, state, _user, _ = nil, customer_accepts_responsibility = false)
      ActiveRecord::Base.transaction do
        tube.requests_as_target.where.not(state: terminated_states).find_each do |request|
          request.transition_to(state)
          new_outer_state = ['started', 'passed', 'qc_complete'].include?(state) ? 'started' : state
          request.outer_request.customer_accepts_responsibility! if customer_accepts_responsibility
          request.outer_request.transition_to(new_outer_state)   if valid_transition?(request.outer_request, new_outer_state)
        end
      end
    end

    ##
    # We find sibling tubes by first finding the outer request type (library completion) and the transfer request type
    # We find all outer requests of the same type in the submission, and match these up with the transfer requests
    # The RIGHT OUTER JOIN ensures we have a null result for any outer requests which don't have matching transfer requests
    # We only pick up open requests, just in case a whole tube has failed / been cancelled.
    def sibling_tubes(tube)
      return [] if tube.submission.nil?
      submission_id     = tube.submission.id
      tfr_request_type  = tube.requests_as_target.first.request_type_id
      outr_request_type = tube.requests_as_target.first.outer_request.request_type_id

      siblings = Asset.select('assets.*, tfr.state AS quick_state').uniq
        .joins([
          'LEFT JOIN requests AS tfr ON tfr.target_asset_id = assets.id',
          'RIGHT OUTER JOIN requests AS outr ON outr.asset_id = tfr.asset_id AND outr.asset_id IS NOT NULL'
        ])
        .where(
          outr: { submission_id: submission_id, request_type_id: outr_request_type, state: Request::Statemachine::OPENED_STATE },
          tfr:  { request_type_id: tfr_request_type, submission_id: submission_id }
        )
        .includes([:uuid_object, :barcode_prefix])

      siblings.map { |s| s.id.nil? ? :no_tube : { name: s.name, uuid: s.uuid, ean13_barcode: s.ean13_barcode, state: s.quick_state } }
    end
  end

  include InitialTube
end
