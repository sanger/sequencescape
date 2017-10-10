# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class RequestEvent < ApplicationRecord
  belongs_to :request, inverse_of: :request_events

  validates :request, :to_state, :current_from, :event_name, presence: true

  validates_inclusion_of :event_name, in: ['created', 'state_changed', 'destroyed']

  scope :current, -> { where(current_to: nil) }

  def self.date_for_state(state)
    where(to_state: state).last.try(:current_from)
  end

  def expire!(date_time)
    raise StandardError, 'This event has already expired!' unless current_to.nil?
    update_attributes!(current_to: date_time)
  end

  def current?
    !current_to?
  end
end
