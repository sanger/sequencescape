# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015 Genome Research Ltd.

module PlatePurpose::Initial
  def self.included(base)
    base.class_eval do
      include PlatePurpose::WorksOnLibraryRequests
    end
  end

  # Initial plates in the pulldown pipelines change the state of the pulldown requests they are being
  # created for to exactly the same state.
  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    broadcast_library_start(plate, user)
    super
  end

  # Ensure that the pulldown library creation request is started
  def broadcast_library_start(plate, user)
    orders = Set.new
    each_well_and_its_library_request(plate) do |_, request|
      orders << request.order_id if request.pending?
    end
    generate_events_for(plate, orders, user)
  end
  private :broadcast_library_start

  def generate_events_for(plate, orders, user)
    orders.each do |order_id|
      BroadcastEvent::LibraryStart.create!(seed: plate, user: user, properties: { order_id: order_id })
    end
  end
  private :generate_events_for
end
