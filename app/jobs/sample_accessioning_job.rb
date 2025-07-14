# frozen_string_literal: true

require 'exception_notification'

# Sends sample data to the ENA or EGA in order to generate an accession number
# Records the generated accession number on the sample
# @see Accession::Submission
SampleAccessioningJob =
  Struct.new(:accessionable) do
    def perform
      submission = Accession::Submission.new(User.find_by(api_key: configatron.accession_local_key), accessionable)
      submission.post

      # update_accession_number returns true if an accession has been supplied, and the sample has been saved.
      # If this returns false, then we fail the job. This should catch any failure situations
      accession_error_message = 'EBI failed to update accession number, data may be invalid'
      submission.update_accession_number || raise(AccessionService::AccessionServiceError, accession_error_message)
    rescue AccessionService::AccessionServiceError => e
      sample_id = accessionable.sanger_sample_id
      job_error_message = "Error performing SampleAccessioningJob for sample '#{sample_id}': #{e.message}"
      Rails.logger.error(job_error_message)
      ExceptionNotifier.notify_exception(e, data: { message: job_error_message })
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
  end
