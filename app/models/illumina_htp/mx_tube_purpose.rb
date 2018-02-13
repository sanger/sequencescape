# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015,2016 Genome Research Ltd.
require_dependency 'tube/purpose'

class IlluminaHtp::MxTubePurpose < Tube::Purpose
  def transition_to(tube, state, user, _ = nil, customer_accepts_responsibility = false)
    transition_customer_requests(tube, mappings[state], user, customer_accepts_responsibility) if mappings[state]
    tube.transfer_requests_as_target.each { |request| request.transition_to(state) }
  end

  def transition_customer_requests(tube, state, user, customer_accepts_responsibility)
    orders = Set.new
    customer_requests(tube).each do |request|
      request.customer_accepts_responsibility! if customer_accepts_responsibility
      request.transition_to(state)
      orders << request.order.id
    end
    generate_events_for(tube, orders, user) if state == 'passed'
  end

  def customer_requests(tube)
    tube.requests_as_target.for_billing.where(state: Request::Statemachine::OPENED_STATE)
  end

  def stock_plate(tube)
    tube.requests_as_target.where_is_a?(CustomerRequest).where.not(requests: { asset_id: nil }).first&.asset&.plate
  end

  def source_plate(tube)
    source_plate_scope(tube).first
  end

  def library_source_plates(tube)
    source_plate_scope(tube).map(&:source_plate)
  end

  def source_plate_scope(tube)
    Plate
      .joins(wells: :requests)
      .where(requests: {
               target_asset_id: tube.id,
               sti_type: [Request::Multiplexing, Request::AutoMultiplexing, Request::LibraryCreation, *Request::LibraryCreation.descendants].map(&:name)
             }).distinct
  end

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
