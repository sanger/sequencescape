# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class CustomerRequestObserver < ActiveRecord::Observer
  def after_create(request)
    request.request_events.create!(
      event_name: 'created',
      to_state: request.state,
      current_from: DateTime.now
    )
  end

  def before_save(request)
    return if request.new_record? || !request.changed.include?('state')
    from_state = request.changes['state'].first
    time = DateTime.now
    request.current_request_event&.expire!(time)
    request.request_events.create!(
      event_name: 'state_changed',
      from_state: from_state,
      to_state: request.state,
      current_from: time
    )
  end

  def before_destroy(request)
    time = DateTime.now
    request.current_request_event&.expire!(time)
    request.request_events.create!(
      event_name: 'destroyed',
      from_state: request.state,
      to_state: request.state,
      current_from: time,
      current_to: time
    )
  end
end
