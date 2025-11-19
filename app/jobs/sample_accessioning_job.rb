# frozen_string_literal: true

require 'exception_notification'

# Wrap standard error to explicitly indicate a job failure
JobFailed = Class.new(StandardError) unless defined?(JobFailed)

# Sends sample data to the ENA or EGA in order to generate an accession number
# Records the generated accession number on the sample
# Records the statuses and response from the failed attempts in the accession statuses
# @see Accession::Submission
SampleAccessioningJob =
  Struct.new(:accessionable) do
    # Retrieve the contact user for accessioning submissions
    def self.contact_user
      User.find_by(api_key: configatron.accession_local_key)
    end

    def perform
      contact_user = self.class.contact_user
      submission = Accession::Submission.new(contact_user, accessionable)
      submission.submit_and_update_accession_number
    rescue StandardError => e
      handle_job_error(e, submission)

      # Raising an error to Delayed::Job will signal that the job should be retried at a later time
      job_failed_message = "#{e.class}: #{e.message}"
      raise JobFailed, job_failed_message
    end

    def reschedule_at(current_time, _attempts)
      current_time + 1.day
    end

    def max_attempts
      3
    end

    def queue_name
      'sample_accessioning'
    end

    # Delayed::Job lifecycle hooks
    # See https://github.com/collectiveidea/delayed_job?tab=readme-ov-file#hooks

    # Called when the job is initially enqueued
    def enqueue(_job)
      create_accession_status
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
    def create_accession_status
      Accession::Status.create_for_sample(accessionable.sample)
    end

    # Update the accessionable status to be in progress for users to see in the UI
    def progress_accession_status
      # Finds the most recent accession status by sample id, and marks it as in progress
      accession_status = Accession::Status.find_latest_or_create_for_sample(accessionable.sample)
      accession_status.mark_in_progress
    end

    # Finds the most recent accession status and removes it
    def succeed_accession_status
      # Wrap in a transaction to prevent race conditions
      Accession::Status.transaction do
        accession_status = Accession::Status.find_latest_or_create_for_sample(accessionable.sample)
        accession_status.destroy
      end
    end

    # Update the accessionable status to failed for users to see in the UI
    def fail_accession_status(message)
      # Wrap in a transaction to prevent race conditions
      Accession::Status.transaction do
        accession_status = Accession::Status.find_latest_or_create_for_sample(accessionable.sample)
        accession_status.mark_failed(message)
      end
    end

    # Update the accessionable status to aborted for users to see in the UI
    def abort_accession_status
      # Wrap in a transaction to prevent race conditions
      Accession::Status.transaction do
        accession_status = Accession::Status.find_latest_or_create_for_sample(accessionable.sample)
        accession_status.mark_aborted
      end
    end

    # Returns a user-friendly error message based on the error type
    def user_error_message(error)
      case error
      when Accession::ExternalValidationError, ActiveModel::ValidationError
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
      ExceptionNotifier.notify_exception(error, data: {
                                           message: message,
                                           sample_name: sample_name,
                                           service_provider: service&.provider.to_s
                                         })
    end

    def handle_job_error(error, submission)
      message = user_error_message(error)
      fail_accession_status(message)
      notify_developers(error, submission)
    end
  end
