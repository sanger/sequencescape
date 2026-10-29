# frozen_string_literal: true

# Processes an API operation in the background, according to its type: it
# runs the operation's tasks in order (ApiOperation::TASKS); for a combined
# reception and work order request, its reception, then its work order. The
# job is saved in the same transaction as the operation, so every saved
# operation has its job.
#
# Each run of a task first commits a started event, so the run is recorded
# even if the task's transaction rolls back or the worker is stopped. The
# task then runs in its own transaction, with the operation's row locked, so
# the task's records, the operation's status and its outcome event commit
# together, or none of them. Tasks only do the work and return their errors;
# the job records whether each task completed or failed.
#
# A task that raises rolls its transaction back. A transient error
# (TRANSIENT_ERRORS) reaches Delayed Job, which runs the job again. Any other
# error is unexpected: the task fails at once, with an error that says so
# (with the model's message when a record is invalid), PSD is notified, and
# the job isn't run again.
#
# With the y26_283_sapio_reception feature flag off, it only logs that the
# operation is ready. Work order processing is added by Y26-289.
class ApiOperation::CoordinatorJob
  # Errors that a later run may not meet, as Rails' MySQL adapter raises
  # them: a deadlock, a lock wait timeout, a lost connection, a failed
  # attempt to connect, and a unique index clash with a record another
  # request saved after this run's checks, such as the same new sample UUID,
  # which the next run's checks then report
  TRANSIENT_ERRORS = [
    ActiveRecord::Deadlocked,
    ActiveRecord::LockWaitTimeout,
    ActiveRecord::ConnectionFailed,
    ActiveRecord::ConnectionNotEstablished,
    ActiveRecord::RecordNotUnique
  ].freeze

  # How long a task is retried for, after transient errors
  RETRY_WINDOW = 4.hours

  # How many times a task is retried after transient errors. The waits
  # between runs double, and add up to RETRY_WINDOW.
  RETRIES = 8

  # @return [Integer] the ID of the operation to process
  attr_reader :api_operation_id

  # @param api_operation_id [Integer] the ID of the operation to process
  def initialize(api_operation_id)
    @api_operation_id = api_operation_id
  end

  # Delayed Job calls this to run the job.
  #
  # @return [void]
  def perform
    api_operation = ApiOperation.find(api_operation_id)
    return log_ready(api_operation) unless reception_enabled?

    loop { break unless run_next_task(api_operation) }
  end

  # Delayed Job calls this when a run raises, to schedule the next run. The
  # waits double, and the RETRIES waits add up to RETRY_WINDOW: about 56
  # seconds, 1.9, 3.8, 7.5, 15 and 30 minutes, 1 hour and 2 hours.
  #
  # @param current_time [Time] when the run failed
  # @param attempts [Integer] the number of failed runs so far, from 1
  # @return [Time] when to run the job again
  def reschedule_at(current_time, attempts)
    current_time +
      (RETRY_WINDOW * Rational(2**(attempts - 1), (2**RETRIES) - 1))
  end

  # Delayed Job reads this to know how many runs to make: the first and
  # RETRIES more.
  #
  # @return [Integer] the number of runs
  def max_attempts
    RETRIES + 1
  end

  private

  def reception_enabled?
    Flipper.enabled?(:y26_283_sapio_reception)
  end

  def log_ready(api_operation)
    Rails.logger.info(
      "ApiOperation #{api_operation.uuid} is ready for processing"
    )
  end

  # Starts the operation's next task, if it has one, then runs it.
  #
  # @return [Boolean] true if a task ran
  def run_next_task(api_operation)
    task = start_next_task(api_operation)
    return false unless task

    run_task(api_operation, task)
  end

  # Records that a run of the operation's next task has started, in its own
  # transaction, so the event is kept whatever happens to the run.
  #
  # @return [String, nil] the task, or nil when there is none
  def start_next_task(api_operation)
    ApiOperation.transaction do
      api_operation.lock!
      task = api_operation.next_task
      api_operation.start_task!(task) if task
      task
    end
  end

  # Runs the task and records its outcome. A transient error is raised
  # again; any other error is unexpected, and fails the task.
  #
  # @return [Boolean] true if the task ran
  def run_task(api_operation, task)
    run_and_record(api_operation, task)
  rescue *TRANSIENT_ERRORS
    raise
  rescue StandardError => e
    fail_after_unexpected_error(api_operation, task, e)
    true
  end

  # Runs the task and records its outcome, in one transaction with the
  # operation's row locked. Locking reloads the operation, so a task another
  # run has finished in the meantime is not run again.
  #
  # @return [Boolean] true if the task ran
  def run_and_record(api_operation, task)
    ApiOperation.transaction do
      api_operation.lock!
      next false unless api_operation.next_task == task

      record_outcome(api_operation, task,
                     task_class(task).new(api_operation).call)
      true
    end
  end

  def record_outcome(api_operation, task, errors)
    if errors.empty?
      api_operation.complete_task!(task)
    else
      api_operation.fail_task!(task, errors)
    end
  end

  # Notifies PSD of the error, then fails the task, in a new transaction
  # with the operation's row locked, unless another run has recorded the
  # task's outcome. PSD is notified first, so the error is reported even if
  # recording the failure raises.
  def fail_after_unexpected_error(api_operation, task, error)
    ExceptionNotifier.notify_exception(
      error, data: { api_operation_id: api_operation.id, task: task }
    )
    ApiOperation.transaction do
      api_operation.lock!
      next unless api_operation.next_task == task

      api_operation.fail_task!(task, [unexpected_error(task, error)])
    end
  end

  # The error recorded for a task that failed because of an unexpected
  # error. It applies to the whole request, so its pointer is empty. An
  # invalid record gives the model's message, so the calling system can see
  # what to change: a rule that reception's checks don't mirror.
  def unexpected_error(task, error)
    reason =
      if error.is_a?(ActiveRecord::RecordInvalid)
        ": #{error.message}"
      else
        ' because of an error in Sequencescape'
      end
    { pointer: '',
      detail: "#{task.humanize} could not be completed#{reason}; " \
              'PSD has been notified' }
  end

  # @return [Class] the class that runs the task
  def task_class(task)
    { 'reception' => ApiOperation::Reception }.fetch(task)
  end
end
