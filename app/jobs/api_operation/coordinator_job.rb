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
# the job records whether each task completed or failed. A task that raises
# rolls its transaction back, and the error reaches Delayed Job.
#
# With the y26_283_sapio_reception feature flag off, it only logs that the
# operation is ready. Work order processing is added by Y26-289.
ApiOperation::CoordinatorJob =
  Struct.new(:api_operation_id) do
    # Delayed Job calls this to run the job.
    #
    # @return [void]
    def perform
      api_operation = ApiOperation.find(api_operation_id)
      return log_ready(api_operation) unless reception_enabled?

      loop { break unless run_next_task(api_operation) }
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

    # Starts the operation's next task, if it has one, then runs it and
    # records its outcome, in one transaction with the operation's row
    # locked. Locking reloads the operation, so a task another run has
    # finished in the meantime is not run again.
    #
    # @return [Boolean] true if a task ran
    def run_next_task(api_operation)
      task = start_next_task(api_operation)
      return false unless task

      ApiOperation.transaction do
        api_operation.lock!
        next false unless api_operation.next_task == task

        record_outcome(api_operation, task,
                       task_class(task).new(api_operation).call)
        true
      end
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

    def record_outcome(api_operation, task, errors)
      if errors.empty?
        api_operation.complete_task!(task)
      else
        api_operation.fail_task!(task, errors)
      end
    end

    # @return [Class] the class that runs the task
    def task_class(task)
      { 'reception' => ApiOperation::Reception }.fetch(task)
    end
  end
