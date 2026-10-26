# frozen_string_literal: true

# Something that happened to a task of an ApiOperation: it completed or
# failed. An operation's events, in order, are its history, and its status
# is the latest one (<task>_<event>). Events are added, not changed.
class ApiOperation::Event < ApplicationRecord
  # What can happen to a task
  EVENTS = %w[completed failed].freeze

  belongs_to :api_operation, optional: false

  validates :task, presence: true
  validates :event, inclusion: { in: EVENTS }
end
