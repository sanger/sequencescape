# frozen_string_literal: true

# Sends the outcome of a finished ApiOperation to the calling system (i.e: Integration Hub). The
# operation queues it in the same transaction as its final status.
#
# It only reads the operation's stored status and errors (ApiOperation::CallbackPayload):
# retrying it never reruns a task. Once the calling system acknowledges the callback, the
# operation's response_delivered_at is set, and a job that finds it set sends nothing.
#
# The send and the timestamp are in one transaction, with the operation's row locked, so two runs
# never send at once and a run that fails sets nothing. Delivery is at least once: if the
# acknowledgement is lost, the callback is sent again.
# The payload and the Idempotency-Key header carry the operation's external_id, which is the
# same in every send, so the calling system can recognise a duplicate.
#
# With no callback URL configured, retrying cannot help: the job notifies PSD and ends,
# leaving the operation's response_delivered_at null.
#
# A failed send (an error, a timeout or a status other than 2xx) is retried by Delayed
# Job on the schedule of ApiOperation::RetrySchedule, the same as the coordinator job's.
# Each failed run adds a failed 'callback' event to the operation. When they run out, PSD is notified
# and the error is logged; response_delivered_at stays null.
class ApiOperation::CallbackJob
  include ApiOperation::RetrySchedule

  # @return [Integer] the ID of the operation whose outcome to send
  attr_reader :api_operation_id

  # @param api_operation_id [Integer] the ID of the operation whose outcome to send
  def initialize(api_operation_id)
    @api_operation_id = api_operation_id
  end

  # Delayed Job calls this to run the job.
  #
  # @return [void]
  # @raise [Faraday::Error] if the callback is not acknowledged, so that Delayed Job retries it
  def perform
    deliver
  rescue HTTPClients::ApiOperationCallbackClient::NotConfigured => e
    record_failure
    report_not_configured(e)
  rescue StandardError
    record_failure
    raise
  end

  # Delayed Job calls this when its last run has failed, then deletes the job.
  #
  # @param job [Delayed::Job] the job's record
  # @return [void]
  def failure(job)
    @delayed_job = job
    message = "Callback retries ran out for ApiOperation #{api_operation_id}"
    Rails.logger.error("#{message}: #{job.last_error}")
    ExceptionNotifier.notify_exception(
      job.error || RetriesExhausted.new(message), data: { message: message, api_operation_id: api_operation_id,
                                                          last_error: job.last_error }
    )
  end

  private

  def deliver
    ApiOperation.transaction do
      api_operation = ApiOperation.lock.find(api_operation_id)
      next if api_operation.response_delivered_at? || !api_operation.finished?

      HTTPClients::ApiOperationCallbackClient.new.deliver(ApiOperation::CallbackPayload.new(api_operation).to_h)
      api_operation.update!(response_delivered_at: Time.current)
    end
  end

  # Adds the failed run to the operation's events. It is done after the delivery's transaction has
  # rolled back, so the event is kept.
  def record_failure
    ApiOperation.find_by(id: api_operation_id)&.record_callback_failure!
  end

  def report_not_configured(error)
    Rails.logger.error("No callback URL to send ApiOperation #{api_operation_id}'s outcome to: #{error.message}")
    ExceptionNotifier.notify_exception(error, data: { api_operation_id: })
  end
end
