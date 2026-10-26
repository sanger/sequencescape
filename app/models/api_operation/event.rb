# frozen_string_literal: true

# Something that happened to a task of an ApiOperation: it completed or
# failed. An operation's events, in order, are its history, and its status
# is the latest one (<task>_<outcome>). Events are added, not changed.
class ApiOperation::Event < ApplicationRecord
  # How a task can end
  OUTCOMES = %w[completed failed].freeze

  belongs_to :api_operation, optional: false

  validates :task, presence: true
  validates :outcome, inclusion: { in: OUTCOMES }
end
