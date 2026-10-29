# frozen_string_literal: true

# How an ApiOperation::CoordinatorJob retries a task after transient errors,
# and gives up on it. Delayed Job reads the schedule and calls the hooks;
# the job checks the retry window before each run. It uses the job's
# api_operation_id.
#
# Retries run out RETRY_WINDOW after a task's first run started, whatever
# went wrong, including workers that were stopped mid-run: the next run
# fails the task instead of running it, with an error that asks for the
# request to be sent again, and PSD is notified. Delayed Job's failure hook
# does the same after max_attempts runs, as a backstop.
module ApiOperation::CoordinatorJob::Retries
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

  # Sent to PSD, not raised, when a task's retries have run out
  class RetriesExhausted < StandardError
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

  # Delayed Job calls this before each run, with the job's record, which
  # holds the last error for the notification when retries run out.
  #
  # @param job [Delayed::Job] the job's record
  # @return [void]
  def before(job)
    @delayed_job = job
  end

  # Delayed Job calls this when its last run (max_attempts) has failed, then
  # deletes the job: a backstop for the retry window. PSD is notified first,
  # as the database may be what failed; then the operation's next task
  # fails, unless it already has an outcome.
  #
  # @param job [Delayed::Job] the job's record
  # @return [void]
  def failure(job)
    @delayed_job = job
    notify_retries_exhausted
    ApiOperation.transaction do
      api_operation = ApiOperation.lock.find(api_operation_id)
      task = api_operation.next_task
      api_operation.fail_task!(task, [retries_exhausted_error(task)]) if task
    end
  end

  private

  # Whether the task's first run started more than RETRY_WINDOW ago
  def retry_window_over?(api_operation, task)
    first_start =
      api_operation.events
        .where(task: task, outcome: ApiOperation::Event::STARTED)
        .minimum(:created_at)
    first_start.present? && first_start < RETRY_WINDOW.ago
  end

  # Notifies PSD that the task's retries have run out, then fails it. The
  # caller holds the operation's row lock.
  def give_up(api_operation, task)
    notify_retries_exhausted(task)
    api_operation.fail_task!(task, [retries_exhausted_error(task)])
  end

  # Notifies PSD that retries have run out, with the last error that the
  # job's record holds. Nothing was raised, so it sends a RetriesExhausted.
  def notify_retries_exhausted(task = nil)
    error = RetriesExhausted.new(
      "Retries ran out for ApiOperation #{api_operation_id}"
    )
    ExceptionNotifier.notify_exception(
      error, data: { api_operation_id: api_operation_id, task: task,
                     last_error: @delayed_job&.last_error }.compact
    )
  end

  # The error recorded for a task whose retries have run out. It applies to
  # the whole request, so its pointer is empty.
  def retries_exhausted_error(task)
    { pointer: '',
      detail: "#{task.humanize} could not be completed because of a " \
              'temporary problem in Sequencescape; send the request ' \
              'again with a new request ID' }
  end
end
