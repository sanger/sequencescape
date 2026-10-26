# frozen_string_literal: true

# A request received by an API operations endpoint, such as the Sapio
# operations endpoint, and its processing progress.
#
# The calling system's request ID (external_id) and the request body
# (payload) are stored exactly as received. The payload digest identifies
# the payload, so a repeated request can be told apart from a changed one.
#
# Its CoordinatorJob runs the tasks of its operation type (TASKS) in order.
# The status names the last completed step: it starts as queued, becomes
# <task>_completed as each task completes, or <task>_failed if a task fails.
# response_delivered_at records when the response was delivered to the
# calling system, and is null until then.
class ApiOperation < ApplicationRecord
  include Uuid::Uuidable

  # The tasks each operation type runs, in order
  TASKS = { 'reception_and_work_order' => %w[reception] }.freeze

  # Raised when a task is completed or failed out of order
  class TaskOrderError < StandardError
  end

  belongs_to :api_application, optional: false

  validates :external_id, :operation_type, :payload, :status, presence: true
  validates :payload_digest, presence: true, length: { is: 64 }

  # Saves an operation and queues its CoordinatorJob in one transaction, so
  # an operation never lacks its job.
  #
  # @param attributes [Hash] the operation's attributes
  # @return [ApiOperation] the saved operation
  def self.create_with_job!(**attributes)
    transaction do
      create!(**attributes).tap do |operation|
        Delayed::Job.enqueue(CoordinatorJob.new(operation.id))
      end
    end
  end

  # The first task not yet completed: the one to run next.
  #
  # @return [String, nil] the task, or nil when a task has failed or all
  #   tasks have completed
  def next_task
    return if status.end_with?('_failed')

    tasks[completed_tasks]
  end

  # Records that the next task has completed.
  #
  # @param task [String] the task, which must be the next task
  # @return [void]
  # @raise [TaskOrderError] if the task is not the next task
  def complete_task!(task)
    check_next_task!(task)
    update!(status: "#{task}_completed")
  end

  # Records that the next task has failed, with what went wrong.
  #
  # @param task [String] the task, which must be the next task
  # @param error_details [Hash] what went wrong
  # @return [void]
  # @raise [TaskOrderError] if the task is not the next task
  def fail_task!(task, error_details)
    check_next_task!(task)
    update!(status: "#{task}_failed", error_details: error_details)
  end

  private

  def tasks
    TASKS.fetch(operation_type)
  end

  # The number of tasks completed so far
  def completed_tasks
    return 0 if status == 'queued'

    tasks.index(status.delete_suffix('_completed')) + 1
  end

  def check_next_task!(task)
    return if task == next_task

    raise TaskOrderError,
          "#{task} is not the next task of ApiOperation #{uuid} (#{status})"
  end
end
