# frozen_string_literal: true

# When Delayed Job runs an ApiOperation job again after a failed run, and how many
# runs it makes. It is shared by ApiOperation::CoordinatorJob and ApiOperation::CallbackJob.
module ApiOperation::RetrySchedule
  # The wait after the job's first failed run. Each later wait is twice the
  # one before, up to MAX_WAIT.
  FIRST_WAIT = 30.seconds

  # The longest wait between runs
  MAX_WAIT = 1.hour

  # How many times the job runs at most, the first run included
  MAX_RUNS = 10

  # Sent to PSD, not raised, when the job's runs are used up and no run's
  # exception is at hand
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
end
