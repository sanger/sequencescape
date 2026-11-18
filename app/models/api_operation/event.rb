# frozen_string_literal: true

# Something that happened to a task of an ApiOperation: a run of it started,
# or it completed or failed. An operation's events, in order, are its
# history, and its status is the latest completed or failed one
# (<task>_<outcome>). Events are added, not changed. A failed delivery of the
# callback (ApiOperation::CallbackJob) is a failed event of the task 'callback',
# which doesn't change the status.
class ApiOperation::Event < ApplicationRecord
  # How a task can end
  OUTCOMES = %w[completed failed].freeze
  FAILED = 'failed'

  # A run of a task started. It sets no status: a started event with no
  # outcome after it is a run that didn't finish, because an error rolled
  # it back or its worker was stopped.
  STARTED = 'started'

  belongs_to :api_operation, optional: false

  validates :task, presence: true
  validates :outcome, inclusion: { in: [STARTED, *OUTCOMES] }
end
