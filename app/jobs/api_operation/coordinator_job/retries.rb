# frozen_string_literal: true

# How an ApiOperation::CoordinatorJob retries a task after transient errors,
# and gives up on it. Delayed Job reads the schedule and calls the hooks;
# the job counts its runs before each run. It uses the job's
# api_operation_id.
#
# The job runs its tasks at most MAX_RUNS times, whatever went wrong.
# Delayed Job counts the job's runs that raised, and calls the failure hook
# after the last one. A run whose worker was stopped mid-run raises nothing,
# so before each run the job also counts the operation's started events,
# which include such runs. Either way the operation's next task fails, with
# an error that asks for the request to be sent again, and PSD is notified.
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

  # The wait after the job's first failed run. Each later wait is twice the
  # one before, up to MAX_WAIT.
  FIRST_WAIT = 30.seconds

  # The longest wait between runs
  MAX_WAIT = 1.hour

  # How many times the job runs its tasks at most, the first run included
  MAX_RUNS = 10

  # Sent to PSD, not raised, when the job's runs are used up
  class RetriesExhausted < StandardError
  end

  # Delayed Job calls this when a run raises, to schedule the next run: 30
  # seconds, then 1, 2, 4, 8, 16 and 32 minutes, then 1 hour, so the last
  # run starts about 3 hours after the first, plus the runs' own time.
  #
  # @param current_time [Time] when the run failed
  # @param attempts [Integer] the number of failed runs so far, from 1
  # @return [Time] when to run the job again
  def reschedule_at(current_time, attempts)
    current_time + [FIRST_WAIT * (2**(attempts - 1)), MAX_WAIT].min
  end

  # Delayed Job reads this to know how many runs to make.
  #
  # @return [Integer] the number of runs
  def max_attempts
    MAX_RUNS
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
  # deletes the job. PSD is notified first, as the database may be what
  # failed; then the operation's next task fails, unless it already has an
  # outcome.
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

  # Whether the job has already run its tasks MAX_RUNS times. It counts the
  # operation's started events, which include runs whose worker was stopped
  # mid-run: Delayed Job doesn't count those, as they raised nothing.
  def runs_used_up?(api_operation)
    api_operation.events.where(outcome: ApiOperation::Event::STARTED)
      .count >= MAX_RUNS
  end

  # Notifies PSD that the job's runs are used up, then fails the task. The
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

  # The error recorded for a task when the job's runs are used up. It
  # applies to the whole request, so its pointer is empty.
  def retries_exhausted_error(task)
    { pointer: '',
      detail: "#{task.humanize} could not be completed because of a " \
              'temporary problem in Sequencescape; send the request ' \
              'again with a new request ID' }
  end
end
