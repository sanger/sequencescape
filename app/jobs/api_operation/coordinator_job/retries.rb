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
  include ApiOperation::RetrySchedule

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
      if task
        api_operation.fail_task!(task, [retries_exhausted_error(task)])
        api_operation.enqueue_callback_if_finished!
      end
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
    api_operation.enqueue_callback_if_finished!
  end

  # Notifies PSD that retries have run out. In the failure hook, the job's
  # record holds the last run's exception, which is sent, so PSD gets its
  # backtrace. A run that gives up before it starts has no exception: it
  # sends a RetriesExhausted, with the last error the record holds, if any.
  def notify_retries_exhausted(task = nil)
    message = "Retries ran out for ApiOperation #{api_operation_id}"
    error = @delayed_job&.error
    data = { message:, api_operation_id:, task: }
    unless error
      error = RetriesExhausted.new(message)
      data[:last_error] = @delayed_job&.last_error
    end
    ExceptionNotifier.notify_exception(error, data: data.compact)
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
