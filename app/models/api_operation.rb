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
  has_many :events,
           -> { order(:id) },
           class_name: 'ApiOperation::Event',
           inverse_of: :api_operation,
           dependent: :destroy

  validates :external_id, :operation_type, :payload, :status, presence: true
  validates :payload_digest, presence: true, length: { is: 64 }
  validates :status, inclusion: { in: :statuses }

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

  # The statuses an operation of its type can have: queued, then each task's
  # completed and failed statuses. None if its type has no tasks.
  #
  # @return [Array<String>] the statuses
  def statuses
    return [] unless TASKS.key?(operation_type)

    ['queued'] +
      tasks.product(Event::EVENTS).map { |task, event| "#{task}_#{event}" }
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
    record_event!(task, 'completed')
  end

  # Records that the next task has failed, with its errors. error_details
  # becomes { "task" => task, "errors" => errors }.
  #
  # @param task [String] the task, which must be the next task
  # @param errors [Array<Hash>] the errors, each with a :detail, and a
  #   :pointer (a JSON pointer) when it is about something in the payload
  # @return [void]
  # @raise [TaskOrderError] if the task is not the next task
  def fail_task!(task, errors)
    check_next_task!(task)
    record_event!(task, 'failed',
                  error_details: { task:, errors: }.deep_stringify_keys)
  end

  private

  # Adds the event and sets the status to match, in one transaction.
  def record_event!(task, event, **attributes)
    transaction do
      update!(status: "#{task}_#{event}", **attributes)
      events.create!(task:, event:)
    end
  end

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
