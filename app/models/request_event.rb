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
