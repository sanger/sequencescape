# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015,2016 Genome Research Ltd.
require_dependency 'tube/purpose'

class IlluminaHtp::MxTubePurpose < Tube::Purpose
  def created_with_request_options(tube)
    tube.requests_as_target.where_is_a?(Request::LibraryCreation).first.try(:request_options_for_creation) || {}
  end

  def transition_to(tube, state, user, _ = nil, customer_accepts_responsibility = false)
    orders = Set.new
    target_requests(tube).each do |request|
      request.customer_accepts_responsibility! if customer_accepts_responsibility
      to_state = request_state(request, state)
      request.transition_to(to_state) unless to_state.nil?
      orders << request.order.id unless request.is_a?(TransferRequest)
    end
    generate_events_for(tube, orders, user) if mappings[state] == 'passed'
  end

  def target_requests(tube)
    tube.requests_as_target.for_billing.where(
      [
        "state IN (?) OR (state='passed' AND sti_type IN (?))",
        Request::Statemachine::OPENED_STATE,
        [TransferRequest, *TransferRequest.descendants].map(&:name)
      ]
)
  end
  private :target_requests

  def stock_plate(tube)
    tube.requests_as_target.where_is_a?(CustomerRequest).where.not(requests: { asset_id: nil }).first.asset.plate
  end

  def library_source_plates(tube)
    Plate
      .joins(wells: :requests)
      .where(requests: {
        target_asset_id: tube.id,
        sti_type: [Request::LibraryCreation, *Request::LibraryCreation.descendants].map(&:name)
      }).distinct.map(&:source_plate)
  end

  def request_state(request, state)
    request.is_a?(TransferRequest) ? state : mappings[state]
  end
  private :request_state

  def mappings
    { 'cancelled' => 'cancelled', 'failed' => 'failed', 'qc_complete' => 'passed' }
  end
  private :mappings

  def generate_events_for(tube, orders, user)
    orders.each do |order_id|
      BroadcastEvent::LibraryComplete.create!(seed: tube, user: user, properties: { order_id: order_id })
    end
  end
  private :generate_events_for
end
