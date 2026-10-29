# frozen_string_literal: true

# Something that happened to a task of an ApiOperation: a run of it started,
# or it completed or failed. An operation's events, in order, are its
# history, and its status is the latest completed or failed one
# (<task>_<outcome>). Events are added, not changed.
class ApiOperation::Event < ApplicationRecord
  # How a task can end
  OUTCOMES = %w[completed failed].freeze

  # A run of a task started. It sets no status: a started event with no
  # outcome after it is a run that didn't finish, because an error rolled
  # it back or its worker was stopped.
  STARTED = 'started'

  belongs_to :api_operation, optional: false

  validates :task, presence: true
  validates :outcome, inclusion: { in: [STARTED, *OUTCOMES] }
end
