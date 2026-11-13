# frozen_string_literal: true

# A task of an ApiOperation: reception, and the work order in Y26-289.
# ApiOperation::CoordinatorJob runs an operation's tasks in the order
# ApiOperation::TASKS gives for its type, and records each one's outcome.
# Each task is a subclass that does its work in #call and returns the errors
# it finds.
#
# To add a task: a subclass, its line in .for, and its name in
# ApiOperation::TASKS after the task it follows. The coordinator job runs
# every task in TASKS while the y26_283_sapio_reception flag is on, so a
# task with a flag of its own needs the job to check that flag too.
class ApiOperation::Task
  # @param name [String] the task's name, as in ApiOperation::TASKS
  # @return [Class] the class of the task with that name
  # @raise [KeyError] if there is no task with that name
  def self.for(name)
    { 'reception' => ApiOperation::Reception }.fetch(name)
  end

  # @param api_operation [ApiOperation] the operation the task is part of
  def initialize(api_operation)
    @api_operation = api_operation
  end

  # Does the task's work. The job runs it in a transaction with the
  # operation's row locked, then records the outcome. When it returns
  # errors, what it wrote is undone and only the failure is recorded. That's
  # a safety net: a task should still check everything before it writes, as
  # reception does, so it reports every problem and doesn't create records
  # only to undo them.
  #
  # @return [Array<Hash>] the errors, each with a :detail, and a :pointer (a
  #   JSON pointer) when it is about something in the payload; empty if the
  #   task succeeded
  # @raise [StandardError] for a problem that isn't in the payload: the job
  #   retries a transient error, and fails the task for any other
  def call
    raise NotImplementedError, "#{self.class} must implement #call"
  end

  private

  # @return [ApiOperation] the operation the task is part of
  attr_reader :api_operation
end
