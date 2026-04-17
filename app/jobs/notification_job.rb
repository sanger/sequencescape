# frozen_string_literal: true

require 'exception_notification'

# Sends a notification to the Integration Hub Notification API.
# The delayed job is required due to the delayed warm-up of the servers for the notification API.
# Designed for accessioning failure notifications, but could be expanded for other uses in the future.
NotificationJob =
  Struct.new(:sample, :message, :failure_groups) do
    def perform
      notification_client = HTTPClients::AccessioningNotificationClient.new
      notification_id = notification_client.create_notification(sample, message, failure_groups)

      Rails.logger.info("Notification '#{notification_id}' created for sample '#{sample.name}'")
    rescue StandardError => e
      handle_job_error(e)

      raise # Raising an error signals that the job should be retried at a later time
    end

    # Implementing exponential backoff for retries: 10 minutes, 2 hours, 21 hours
    def reschedule_at(current_time, attempts)
      case attempts
      when 1
        current_time + 10.minutes
      when 2
        current_time + 2.hours
      else
        current_time + 21.hours # under 24 hour delay from first attempt to allow for the next day's accessioning retry
      end
    end

    def max_attempts
      3
    end

    def queue_name
      'notifications'
    end

    # Delayed::Job lifecycle hooks
    # See https://github.com/collectiveidea/delayed_job?tab=readme-ov-file#hooks

    private

    # Log and email developers of the notification failure error
    def handle_job_error(error)
      Rails.logger.error("Failed to create accessioning notification for sample '#{sample.name}': #{error.message}")
      ExceptionNotifier.notify_exception(error)
    end
  end
