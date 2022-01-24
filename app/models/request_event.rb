# frozen_string_literal: true
class RequestEvent < ApplicationRecord # rubocop:todo Style/Documentation
  belongs_to :request, inverse_of: :request_events

  validates :event_name, inclusion: { in: %w[created state_changed destroyed] }

  scope :current, -> { where(current_to: nil) }

  def self.date_for_state(state)
    where(to_state: state).last.try(:current_from)
  end

  def expire!(date_time)
    raise StandardError, 'This event has already expired!' unless current_to.nil?

    update!(current_to: date_time)
  end

  def current?
    !current_to?
  end
end
