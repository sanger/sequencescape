# frozen_string_literal: true

require 'exception_notification'

# Sends sample data to the ENA or EGA in order to generate an accession number
# Records the generated accession number on the sample
# Records the statuses and response from the failed attempts in the accession statuses
# @see Accession::Submission
SampleAccessioningJob =
  Struct.new(:accessionable, :event_user) do
    # Retrieve the contact user for accessioning submissions
    def self.contact_user
      User.find_by(api_key: configatron.accession_local_key)
    end

    def perform
      contact_user = self.class.contact_user
      submission = Accession::Submission.new(contact_user, accessionable)
      accessionable.validate! # See Accession::Sample.validate! in lib/accession/sample.rb
      submission.submit_accession(event_user)
    rescue StandardError => e
      handle_job_error(e, submission)

      raise e # Raising an error signals that the job should be retried at a later time
    end

    def reschedule_at(current_time, _attempts)
      # When changing, also update attempt description text in app/views/samples/_accession_statuses.html.erb
      current_time + 1.minute
    end

    def max_attempts
      # When changing, also update attempt description text in app/views/samples/_accession_statuses.html.erb
      3
    end

    def queue_name
      'sample_accessioning'
    end

    # Delayed::Job lifecycle hooks
    # See https://github.com/collectiveidea/delayed_job?tab=readme-ov-file#hooks
    #
    # Desired status cycle is:
    #
    #   Enqueue -> Create 'queued' status
    #   Before  -> Update latest 'queued' status to 'processing' status, or create new 'processing' status
    #   Failure -> Update latest 'processing' status to 'failed' status
    #   Abort   -> Update latest 'failed' status to 'aborted' status
    #   Success -> Remove all statuses for the sample
    #
    # The overall result is that a status record exists for each accessioning attempt, ie:
    # 3 attempts would result in 3 status records.
    # Once successful, all status records are removed, however if the sample is not ultimately
    # accessioned then the latest status records will remain in the database.

    # Called when the job is initially enqueued
    def enqueue(_job)
      create_queued_accession_status
    end

    # Called before the job is run
    def before(_job)
      progress_accession_status
    end

    # Called after the job has completed successfully
    def success(_job)
      succeed_accession_status
    end

    # Called after the job has failed max_attempts times
    def failure(_job)
      abort_accession_status
    end

    private

    # Creates a new accession status for the sample for users to see in the UI
    def create_queued_accession_status
      Accession::SampleStatus.create_for_sample(accessionable.sample)
    end

    # Update the accessionable status to be in progress for users to see in the UI
    def progress_accession_status
      Accession::SampleStatus.find_latest_and_update!(accessionable.sample,
                                                      status: 'queued',
                                                      attributes: { status: 'processing' })
    rescue ActiveRecord::RecordNotFound
      # This is not unexpected due to the retry mechanism: create a new status
      Accession::SampleStatus.create_for_sample(accessionable.sample, 'processing')
    end

    # Removes all accession statuses for the sample on successful accessioning
    def succeed_accession_status
      sample_id = accessionable.sample.id
      Accession::SampleStatus.where(sample_id:).delete_all
    end

    # Update the accessionable status to failed for users to see in the UI
    def fail_accession_status(message)
      Accession::SampleStatus.find_latest_and_update!(accessionable.sample,
                                                      status: 'processing',
                                                      attributes: { status: 'failed', message: message })
    rescue ActiveRecord::RecordNotFound
      # If no status exists, log a warning and create one
      Rails.logger.warn('Potential data inconsistency. No existing accession processing status found for ' \
                        "sample ID #{accessionable.sample.id} when trying to mark as failed.")
      Accession::SampleStatus.create_for_sample(accessionable.sample, 'failed', message)
    end

    # Update the accessionable status to aborted for users to see in the UI
    def abort_accession_status
      Accession::SampleStatus.find_latest_and_update!(accessionable.sample,
                                                      status: 'failed',
                                                      attributes: { status: 'aborted' })
    rescue ActiveRecord::RecordNotFound
      # If no status exists, log a warning and create one
      Rails.logger.warn('Potential data inconsistency. No existing accession failed status found for ' \
                        "sample ID #{accessionable.sample.id} when trying to mark as aborted.")
      Accession::SampleStatus.create_for_sample(accessionable.sample, 'aborted')
    end

    # Returns a user-friendly error message based on the error type
    def user_error_message(error)
      case error
      when Accession::ExternalValidationError, ActiveModel::ValidationError, ActiveRecord::RecordInvalid
        error.message
      when Faraday::Error
        'A network error occurred during accessioning and no response was received.'
      else
        'An internal error occurred during accessioning.'
      end
    end

    # Log and email developers of the accessioning error
    def notify_developers(error, submission)
      sample_name = submission.sample.sample.name
      service = submission.service
      message = "SampleAccessioningJob failed for sample '#{sample_name}': #{error.message}"

      Rails.logger.error(message)
      # Log backtrace for debugging purposes
      Rails.logger.debug(error.backtrace.join("\n")) if error.backtrace
      ExceptionNotifier.notify_exception(error, data: {
                                           message: message,
                                           sample_name: sample_name,
                                           service_provider: service&.provider.to_s
                                         })
    end

    def handle_job_error(error, submission)
      message = user_error_message(error)
      fail_accession_status(message)

      notify_on_internal_failures = Flipper.enabled?(:y25_705_notify_on_internal_accessioning_validation_failures)
      notify_on_external_failures = Flipper.enabled?(:y25_705_notify_on_external_accessioning_validation_failures)

      case error
      when Accession::ExternalValidationError
        notify_developers(error, submission) if notify_on_internal_failures
      when ActiveModel::ValidationError, ActiveRecord::RecordInvalid
        notify_developers(error, submission) if notify_on_external_failures
      end
    end
  end
